import Foundation

/// The outcome of the first sign-in step (AUTH-01).
public enum SignInResult: Sendable, Equatable {
    case signedIn(SessionTokens)
    /// AUTH-02: the account has two-factor on; finish with `verifyMFA`.
    case mfaRequired(mfaToken: String)
}

/// Everything screens ask of the API. Screens never call HTTP directly (CLIENT-ARCHITECTURE §1).
/// `LiveHubService` talks to the Platform API; `DemoHubService` serves fixtures for previews and design review.
public protocol HubService: Sendable {
    func signIn(email: String, password: String) async throws -> SignInResult
    func verifyMFA(mfaToken: String, code: String) async throws -> SessionTokens
    func signOut(allSessions: Bool) async throws

    func currentUser() async throws -> UserSummary
    func capabilities() async throws -> Capabilities

    func users(_ query: UserQuery, cursor: String?) async throws -> Page<UserSummary>
    func user(id: String) async throws -> UserSummary
    func access(userID: String) async throws -> [AccessSummary]
    func applications(cursor: String?) async throws -> Page<ApplicationSummary>
    func apiKeys(includeInactive: Bool, cursor: String?) async throws -> Page<APIKeySummary>
    func createAPIKey(_ draft: NewAPIKey, idempotencyKey: String) async throws -> CreatedAPIKey
    func revokeAPIKey(id: String) async throws
    func auditEvents(cursor: String?) async throws -> Page<AuditEntry>
    func roles(scope: String?) async throws -> [RoleSummary]
    func permissionCatalog() async throws -> [String]
}
