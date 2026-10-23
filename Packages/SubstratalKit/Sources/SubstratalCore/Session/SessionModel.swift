import Foundation
import Observation

/// The signed-in state the whole app observes (CLIENT-ARCHITECTURE §3, §5).
@MainActor @Observable
public final class SessionModel {
    public enum Phase: Equatable {
        /// Checking the Keychain for a surviving session on launch.
        case restoring
        case signedOut
        /// AUTH-02: password accepted, two-factor code needed.
        case awaitingMFA(mfaToken: String)
        case signedIn
    }

    public private(set) var phase: Phase = .restoring
    public private(set) var user: UserSummary?
    public private(set) var capabilities: Capabilities = .none
    /// A sign-in or MFA error to show inline on AUTH-01 / AUTH-02.
    public var lastError: APIError?
    public private(set) var isWorking = false

    public let service: any HubService
    private let tokens: TokenStore?

    public init(service: any HubService, tokens: TokenStore?) {
        self.service = service
        self.tokens = tokens
    }

    /// Restores a session from the Keychain refresh token, or shows AUTH-01.
    public func restore() async {
        guard let tokens else { phase = .signedOut; return }
        guard await tokens.hasStoredSession else { phase = .signedOut; return }
        do {
            try await tokens.refresh()
            try await loadIdentity()
            phase = .signedIn
        } catch {
            phase = .signedOut
        }
    }

    public func signIn(email: String, password: String) async {
        await run {
            switch try await service.signIn(email: email, password: password) {
            case .signedIn:
                try await loadIdentity()
                phase = .signedIn
            case .mfaRequired(let token):
                phase = .awaitingMFA(mfaToken: token)
            }
        }
    }

    public func verifyMFA(code: String) async {
        guard case .awaitingMFA(let token) = phase else { return }
        await run {
            _ = try await service.verifyMFA(mfaToken: token, code: code)
            try await loadIdentity()
            phase = .signedIn
        }
    }

    public func cancelMFA() { phase = .signedOut }

    /// Sign out = `POST /auth/logout`, then wipe credentials and caches (CLIENT-ARCHITECTURE §3 rule 4).
    public func signOut(everywhere: Bool = false) async {
        try? await service.signOut(allSessions: everywhere)
        await tokens?.clear()
        user = nil
        capabilities = .none
        phase = .signedOut
    }

    /// Recomputed on sign-in, on foreground, and after any `403` (CLIENT-ARCHITECTURE §5).
    public func refreshCapabilities() async {
        if let fresh = try? await service.capabilities() { capabilities = fresh }
    }

    private func loadIdentity() async throws {
        async let me = service.currentUser()
        async let caps = service.capabilities()
        user = try await me
        capabilities = (try? await caps) ?? .none
    }

    private func run(_ work: () async throws -> Void) async {
        isWorking = true
        lastError = nil
        defer { isWorking = false }
        do { try await work() } catch let error as APIError { lastError = error } catch { lastError = .transport(error.localizedDescription) }
    }
}
