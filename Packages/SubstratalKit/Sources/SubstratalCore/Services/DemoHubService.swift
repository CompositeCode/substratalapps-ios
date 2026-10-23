import Foundation

/// Fixture-backed `HubService` for SwiftUI previews, UI tests and design review, with no network.
/// Data mirrors the examples in the API reference so screens look like they will against production.
public actor DemoHubService: HubService {
    private var keys: [APIKeySummary]
    private let now = Date()

    public init() {
        keys = DemoHubService.seedKeys
    }

    public func signIn(email: String, password: String) async throws -> SignInResult {
        try await Task.sleep(for: .milliseconds(300))
        guard !password.isEmpty else { throw APIError.unauthenticated }
        return .mfaRequired(mfaToken: "mfa_demo")
    }

    public func verifyMFA(mfaToken: String, code: String) async throws -> SessionTokens {
        guard code.count == 6 else { throw APIError.validation(fields: [.init(field: "code", code: "invalid_mfa_code")]) }
        return SessionTokens(accessToken: "demo", expiresIn: 900, refreshToken: "rtk_demo", sessionID: "ses_demo", userID: "usr_01JAG0SYSTEM00000000000000")
    }

    public func signOut(allSessions: Bool) async throws {}

    public func currentUser() async throws -> UserSummary {
        UserSummary(id: "usr_01JAG0SYSTEM00000000000000", email: "adron@substratalapps.com", status: .active, mfaEnabled: true, plan: "standard")
    }

    public func capabilities() async throws -> Capabilities { .superadmin }

    public func users(_ query: UserQuery, cursor: String?) async throws -> Page<UserSummary> {
        let filtered = Self.users.filter { user in
            (query.text.isEmpty || user.email.localizedCaseInsensitiveContains(query.text) || user.id.contains(query.text))
                && (query.status == nil || user.status == StatusKind(rawValue: query.status!))
        }
        return Page(items: filtered, nextCursor: nil)
    }

    public func user(id: String) async throws -> UserSummary {
        guard let user = Self.users.first(where: { $0.id == id }) else { throw APIError.notFound }
        return user
    }

    public func access(userID: String) async throws -> [AccessSummary] {
        [
            AccessSummary(applicationID: "app_timetrack", applicationName: "TimeTrack", status: .active, sources: ["subscription", "admin_grant"], platformManaged: false),
            AccessSummary(applicationID: "app_invoicer", applicationName: "Invoicer", status: .disabled, sources: ["purchase"], platformManaged: false),
            AccessSummary(applicationID: "app_notes", applicationName: "Field Notes", status: .active, sources: ["free"], platformManaged: true),
            AccessSummary(applicationID: "app_ledger", applicationName: "Ledger", status: .scheduled, sources: ["trial"], platformManaged: false),
        ]
    }

    public func applications(cursor: String?) async throws -> Page<ApplicationSummary> {
        Page(items: Self.applications, nextCursor: nil)
    }

    public func apiKeys(includeInactive: Bool, cursor: String?) async throws -> Page<APIKeySummary> {
        Page(items: includeInactive ? keys : keys.filter { $0.status == .active }, nextCursor: nil)
    }

    public func createAPIKey(_ draft: NewAPIKey, idempotencyKey: String) async throws -> CreatedAPIKey {
        let secret = "satk_\(draft.mode)_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let key = APIKeySummary(id: "key_" + UUID().uuidString.prefix(26).replacingOccurrences(of: "-", with: "").uppercased(),
                                name: draft.name, scope: draft.scope, mode: draft.mode, intendedUse: draft.intendedUse,
                                restrictDestructive: draft.intendedUse == "agent", permissions: draft.permissions.sorted(),
                                secretHint: "…" + secret.suffix(4), expiresAt: draft.expiresAt, createdAt: .now)
        keys.insert(key, at: 0)
        return CreatedAPIKey(key: key, secret: secret)
    }

    public func revokeAPIKey(id: String) async throws {
        guard let index = keys.firstIndex(where: { $0.id == id }) else { throw APIError.notFound }
        keys[index].revokedAt = .now
    }

    public func auditEvents(cursor: String?) async throws -> Page<AuditEntry> {
        let actions = ["entitlement.disabled", "role.assigned", "api_key.created", "user.suspended", "application.updated",
                       "entitlement.granted", "user.sessions_revoked", "webhook.secret_rotated", "api_key.rotated", "user.created"]
        let items = actions.enumerated().map { index, action in
            AuditEntry(id: "evt_01JAG7X3P8QY110M9N807P6Q\(index)R", action: action, actorType: index % 3 == 0 ? "api_key" : "user",
                       actorID: index % 3 == 0 ? "key_01JAGE5F6G7H8J9K011M2N304P" : "usr_01JAG9STAFF000000000000000",
                       targetType: String(action.split(separator: ".").first ?? ""), targetID: "ent_01JAG9F4Q1W2E3R4T5Y6V7J809",
                       applicationID: index % 2 == 0 ? "app_invoicer" : nil, requestID: "req_7c1e9a2f4b\(index)",
                       timestamp: now.addingTimeInterval(TimeInterval(-index * 2_700)))
        }
        return Page(items: items, nextCursor: nil)
    }

    public func roles(scope: String?) async throws -> [RoleSummary] {
        [
            RoleSummary(id: "role_platform_superadmin", name: "superadmin", scope: "platform", description: "Every platform permission.", permissions: Capabilities.superadmin.platformPermissions.sorted(), seed: true, assignmentCount: 1),
            RoleSummary(id: "role_platform_support", name: "support", scope: "platform", description: "Front-line support.", permissions: ["users.list", "entitlements.manage", "audit.view", "tenants.manage", "billing.manage"], seed: true, assignmentCount: 3),
            RoleSummary(id: "role_platform_billing_admin", name: "billing_admin", scope: "platform", description: "Billing and refunds.", permissions: ["billing.manage", "billing.refund", "audit.view", "users.list"], seed: true, assignmentCount: 1),
            RoleSummary(id: "role_platform_member", name: "member", scope: "platform", description: "Every account. Grants nothing beyond self-service.", permissions: [], seed: true, assignmentCount: 214),
            RoleSummary(id: "role_platform_support_readonly", name: "support_readonly", scope: "platform", description: "Look, don't touch.", permissions: ["users.list", "audit.view"], seed: false, assignmentCount: 2),
        ]
    }

    public func permissionCatalog() async throws -> [String] {
        Capabilities.superadmin.platformPermissions.sorted() + ["app.timetrack.export", "app.timetrack.manage_members", "app.invoicer.view", "app.invoicer.send"]
    }

    // MARK: Fixtures

    static let users: [UserSummary] = [
        UserSummary(id: "usr_01JAG0SYSTEM00000000000000", email: "adron@substratalapps.com", status: .active, mfaEnabled: true, plan: "standard", createdAt: .now.addingTimeInterval(-86_400 * 40), lastLoginAt: .now.addingTimeInterval(-600)),
        UserSummary(id: "usr_01JAG3Z9X8QS3F6K2M4N5P6R7S", email: "jordan.lee@example.com", status: .active, mfaEnabled: true, plan: "standard", createdAt: .now.addingTimeInterval(-86_400 * 21), lastLoginAt: .now.addingTimeInterval(-7_200)),
        UserSummary(id: "usr_01JAG4A1B2C3D4E5F6G7H8J9K0", email: "dana.okafor@example.com", status: .invited, emailVerified: false, createdAt: .now.addingTimeInterval(-86_400 * 2)),
        UserSummary(id: "usr_01JAG5M6N7P8Q9R0S1T2V3W4X5", email: "sam.rivera@example.org", status: .suspended, createdAt: .now.addingTimeInterval(-86_400 * 90), lastLoginAt: .now.addingTimeInterval(-86_400 * 12)),
        UserSummary(id: "usr_01JAG6Y7Z8A9B0C1D2E3F4G5H6", email: "priya.n@example.com", status: .active, plan: "free", createdAt: .now.addingTimeInterval(-86_400 * 5), lastLoginAt: .now.addingTimeInterval(-86_400)),
        UserSummary(id: "usr_01JAG7J8K9L0M1N2P3Q4R5S6T7", email: "qa+1@example.com", status: .active, testMode: true, createdAt: .now.addingTimeInterval(-3_600), expiresAt: .now.addingTimeInterval(3 * 3_600)),
    ]

    static let applications: [ApplicationSummary] = [
        ApplicationSummary(id: "app_hub", slug: "hub", name: "Substratal Hub", summary: "This app: dashboard, inbox and administration.", visibility: "internal", accessTier: "free", reviewStatus: .active),
        ApplicationSummary(id: "app_timetrack", slug: "timetrack", name: "TimeTrack", summary: "Time tracking and timesheet export for teams.", visibility: "public", accessTier: "standard", reviewStatus: .active),
        ApplicationSummary(id: "app_invoicer", slug: "invoicer", name: "Invoicer", summary: "Send and track invoices.", visibility: "public", accessTier: "standard", reviewStatus: .active),
        ApplicationSummary(id: "app_notes", slug: "notes", name: "Field Notes", summary: "Quick notes that sync everywhere.", visibility: "public", accessTier: "free", reviewStatus: .active),
        ApplicationSummary(id: "app_ledger", slug: "ledger", name: "Ledger", summary: "Third-party bookkeeping, awaiting review.", visibility: "public", accessTier: "standard", reviewStatus: .pending),
    ]

    static let seedKeys: [APIKeySummary] = [
        APIKeySummary(id: "key_01JAGE5F6G7H8J9K011M2N304P", name: "timetrack-backend", scope: "app_timetrack", mode: "live", intendedUse: "service", restrictDestructive: false, permissions: ["entitlements.manage", "users.list"], secretHint: "…6c8e", lastUsedAt: .now.addingTimeInterval(-90), expiresAt: .now.addingTimeInterval(86_400 * 340), createdAt: .now.addingTimeInterval(-86_400 * 25)),
        APIKeySummary(id: "key_01JAGF6G7H8J9K011M2N304P5Q", name: "support-assistant-mcp", scope: "platform", mode: "live", intendedUse: "agent", restrictDestructive: true, permissions: ["audit.view", "users.list"], secretHint: "…a41f", lastUsedAt: .now.addingTimeInterval(-86_400 * 3), createdAt: .now.addingTimeInterval(-86_400 * 18)),
        APIKeySummary(id: "key_01JAGG7H8J9K011M2N304P5Q6R", name: "invoicer-tests", scope: "app_invoicer", mode: "test", intendedUse: "service", restrictDestructive: false, permissions: ["entitlements.manage"], secretHint: "…0b2d", expiresAt: .now.addingTimeInterval(86_400 * 9), createdAt: .now.addingTimeInterval(-86_400 * 50)),
        APIKeySummary(id: "key_01JAGH8J9K011M2N304P5Q6R7S", name: "billing-webhook-handler (old)", scope: "platform", mode: "live", intendedUse: "service", restrictDestructive: false, permissions: ["entitlements.manage"], secretHint: "…77aa", revokedAt: .now.addingTimeInterval(-86_400 * 7), createdAt: .now.addingTimeInterval(-86_400 * 120)),
    ]
}
