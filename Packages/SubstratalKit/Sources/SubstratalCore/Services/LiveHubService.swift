import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import SubstratalAPI

/// `HubService` backed by the Platform API through the generated client.
///
/// Middleware order matters: errors are mapped outermost, so `AuthMiddleware` (innermost) still sees a raw
/// `401` and can refresh and replay before anything is turned into an `APIError`.
public struct LiveHubService: HubService {
    private let client: Client
    private let tokens: TokenStore

    public init(configuration: APIConfiguration, tokens: TokenStore, versionMonitor: APIVersionMonitor) {
        self.tokens = tokens
        let transport = URLSessionTransport()
        let shared: [any ClientMiddleware] = [
            ErrorMappingMiddleware(),
            RequestContextMiddleware(userAgent: configuration.userAgent),
            APIVersionMiddleware(monitor: versionMonitor),
        ]
        client = Client(serverURL: configuration.baseURL, transport: transport, middlewares: shared + [AuthMiddleware(tokens: tokens)])

        // Refresh goes through a client without AuthMiddleware, so a failed refresh can't recurse.
        let refreshClient = Client(serverURL: configuration.baseURL, transport: transport, middlewares: shared)
        Task {
            await tokens.setRefresher { refreshToken in
                try await unwrapping {
                    let session = try await refreshClient.auth_refreshToken(body: .json(.init(refreshToken: refreshToken))).ok.body.json
                    return SessionTokens(session)
                }
            }
        }
    }

    // MARK: Session

    public func signIn(email: String, password: String) async throws -> SignInResult {
        try await unwrapping {
            switch try await client.auth_login(body: .json(.init(email: email, password: password))).ok.body.json {
            case .AuthSession(let session):
                let fresh = SessionTokens(session)
                await tokens.store(fresh)
                return .signedIn(fresh)
            case .MfaChallenge(let challenge):
                return .mfaRequired(mfaToken: challenge.mfaToken)
            }
        }
    }

    public func verifyMFA(mfaToken: String, code: String) async throws -> SessionTokens {
        try await unwrapping {
            let session = try await client.auth_verifyMfa(body: .json(.init(mfaToken: mfaToken, code: code))).ok.body.json
            let fresh = SessionTokens(session)
            await tokens.store(fresh)
            return fresh
        }
    }

    public func signOut(allSessions: Bool) async throws {
        defer { Task { await tokens.clear() } }
        _ = try? await unwrapping { try await client.auth_logout(body: .json(.init(allSessions: allSessions))) }
    }

    public func currentUser() async throws -> UserSummary {
        try await unwrapping { UserSummary(try await client.users_get(path: .init(id: "me")).ok.body.json) }
    }

    /// CLIENT-ARCHITECTURE §5. A `403` on the role catalog means "no admin permissions", not an error.
    public func capabilities() async throws -> Capabilities {
        try await unwrapping {
            async let assignments = client.roles_listForUser(path: .init(id: "me"), query: .init(limit: 100))
            async let owned = client.applications_list(query: .init(limit: 100, owned: true))
            async let tenants = client.tenants_list(query: .init(limit: 100))

            let heldRoleIDs = Set(try await assignments.ok.body.json.value2.data?.compactMap(\.roleId) ?? [])
            var permissions = Set<String>()
            if let catalog = try? await client.roles_list(query: .init(limit: 100, scope: "platform")).ok.body.json.value2.data {
                for role in catalog where heldRoleIDs.contains(role.value2.id ?? "") {
                    permissions.formUnion(role.value1.permissions)
                }
            }
            let me = try await currentUser()
            return Capabilities(
                platformPermissions: permissions,
                ownedApplicationIDs: try await owned.ok.body.json.value2.data?.compactMap(\.id) ?? [],
                ownedTenantIDs: (try? await tenants.ok.body.json.value2.data?.compactMap(\.id)) ?? [],
                plan: me.plan ?? "free"
            )
        }
    }

    // MARK: Administration

    public func users(_ query: UserQuery, cursor: String?) async throws -> Page<UserSummary> {
        try await unwrapping {
            let page = try await client.users_list(query: .init(
                limit: 25, cursor: cursor, status: query.status,
                q: query.text.isEmpty ? nil : query.text,
                roleId: query.roleIDs.isEmpty ? nil : query.roleIDs
            )).ok.body.json
            return Page(items: page.value2.data?.map(UserSummary.init) ?? [], nextCursor: page.value1.page.nextCursor)
        }
    }

    public func user(id: String) async throws -> UserSummary {
        try await unwrapping { UserSummary(try await client.users_get(path: .init(id: id)).ok.body.json) }
    }

    public func access(userID: String) async throws -> [AccessSummary] {
        try await unwrapping {
            let rows = try await client.entitlements_listForUser(path: .init(id: userID), query: .init(limit: 100)).ok.body.json.value2.data ?? []
            let byApp = Dictionary(grouping: rows, by: { $0.applicationId ?? "unknown" })
            return byApp.keys.sorted().map { appID in
                let paths = byApp[appID] ?? []
                let statuses = paths.compactMap(\.status)
                let resolved: StatusKind = statuses.contains("active") ? .active : statuses.first.map(StatusKind.init(rawValue:)) ?? .none
                let sources = paths.compactMap(\.source)
                return AccessSummary(applicationID: appID, applicationName: appID, status: resolved, sources: sources,
                                     platformManaged: sources.allSatisfy { $0 == "free" || $0 == "subscription" })
            }
        }
    }

    // MARK: Developer

    public func applications(cursor: String?) async throws -> Page<ApplicationSummary> {
        try await unwrapping {
            let page = try await client.applications_list(query: .init(limit: 50, cursor: cursor)).ok.body.json
            return Page(items: page.value2.data?.map(ApplicationSummary.init) ?? [], nextCursor: page.value1.page.nextCursor)
        }
    }

    public func apiKeys(includeInactive: Bool, cursor: String?) async throws -> Page<APIKeySummary> {
        try await unwrapping {
            let page = try await client.apiKeys_list(query: .init(limit: 50, cursor: cursor, includeInactive: includeInactive)).ok.body.json
            return Page(items: page.value2.data?.map(APIKeySummary.init) ?? [], nextCursor: page.value1.page.nextCursor)
        }
    }

    public func createAPIKey(_ draft: NewAPIKey, idempotencyKey: String) async throws -> CreatedAPIKey {
        try await RequestContext.$idempotencyKey.withValue(idempotencyKey) {
            try await unwrapping {
                let created = try await client.apiKeys_create(body: .json(.init(
                    name: draft.name, scope: draft.scope, permissions: draft.permissions.sorted(), mode: draft.mode,
                    intendedUse: draft.intendedUse, expiresAt: draft.expiresAt
                ))).created.body.json
                return CreatedAPIKey(key: APIKeySummary(created.value1), secret: created.value2.secret ?? "")
            }
        }
    }

    public func revokeAPIKey(id: String) async throws {
        try await unwrapping { _ = try await client.apiKeys_delete(path: .init(id: id)).noContent }
    }

    public func auditEvents(cursor: String?) async throws -> Page<AuditEntry> {
        try await unwrapping {
            let page = try await client.audit_list(query: .init(limit: 50, cursor: cursor)).ok.body.json
            return Page(items: page.value2.data?.map(AuditEntry.init) ?? [], nextCursor: page.value1.page.nextCursor)
        }
    }

    public func roles(scope: String?) async throws -> [RoleSummary] {
        try await unwrapping {
            try await client.roles_list(query: .init(limit: 100, scope: scope)).ok.body.json.value2.data?.map(RoleSummary.init) ?? []
        }
    }

    public func permissionCatalog() async throws -> [String] {
        try await unwrapping {
            try await client.permissions_list(query: .init(limit: 200)).ok.body.json.value2.data?.compactMap(\.key) ?? []
        }
    }
}

// MARK: - Mapping generated types to domain models

extension SessionTokens {
    init(_ session: Components.Schemas.AuthSession) {
        self.init(accessToken: session.accessToken, expiresIn: session.expiresIn, refreshToken: session.refreshToken,
                  sessionID: session.sessionId, userID: session.userId)
    }
}

extension UserSummary {
    init(_ user: Components.Schemas.User) {
        self.init(id: user.id ?? "", email: user.email ?? "", status: StatusKind(rawValue: user.status ?? "active"),
                  mfaEnabled: user.mfaEnabled ?? false, emailVerified: user.emailVerified ?? false, testMode: user.testMode ?? false,
                  plan: user.plan, createdAt: user.createdAt, lastLoginAt: user.lastLoginAt, expiresAt: user.expiresAt)
    }
}

extension ApplicationSummary {
    init(_ app: Components.Schemas.ApplicationSummary) {
        self.init(id: app.id ?? "", slug: app.slug ?? "", name: app.name ?? app.slug ?? "", summary: app.description,
                  visibility: app.visibility ?? "public", accessTier: app.accessTier ?? "standard",
                  reviewStatus: StatusKind.applicationReview(app.reviewStatus ?? "approved"))
    }
}

extension APIKeySummary {
    init(_ key: Components.Schemas.ApiKey) {
        self.init(id: key.value2.id ?? "", name: key.value1.name, scope: key.value1.scope, mode: key.value1.mode,
                  intendedUse: key.value1.intendedUse ?? "service", restrictDestructive: key.value1.restrictDestructive ?? false,
                  permissions: key.value1.permissions, secretHint: key.value2.secretHint, lastUsedAt: key.value2.lastUsedAt,
                  expiresAt: key.value1.expiresAt, revokedAt: key.value2.revokedAt, createdAt: key.value2.createdAt)
    }
}

extension AuditEntry {
    init(_ event: Components.Schemas.AuditEvent) {
        self.init(id: event.id ?? "", action: event.action ?? "", actorType: event.actor?._type ?? "system",
                  actorID: event.actor?.id ?? "system", targetType: event.target?._type, targetID: event.target?.id,
                  applicationID: event.applicationId, requestID: event.requestId, timestamp: event.timestamp ?? .now)
    }
}

extension RoleSummary {
    init(_ role: Components.Schemas.Role) {
        self.init(id: role.value2.id ?? "", name: role.value1.name, scope: role.value1.scope, description: role.value1.description,
                  permissions: role.value1.permissions, seed: role.value2.seed ?? false, assignmentCount: role.value2.assignmentCount ?? 0)
    }
}
