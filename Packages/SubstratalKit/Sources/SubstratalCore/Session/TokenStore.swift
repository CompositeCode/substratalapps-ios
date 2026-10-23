import Foundation

/// A fresh platform session from login, MFA verify, or refresh.
public struct SessionTokens: Sendable, Equatable {
    public let accessToken: String
    public let expiresAt: Date
    public let refreshToken: String
    public let sessionID: String
    public let userID: String

    public init(accessToken: String, expiresIn: Int, refreshToken: String, sessionID: String, userID: String, now: Date = .now) {
        self.accessToken = accessToken
        self.expiresAt = now.addingTimeInterval(TimeInterval(expiresIn))
        self.refreshToken = refreshToken
        self.sessionID = sessionID
        self.userID = userID
    }
}

/// Holds tokens and performs single-flight refresh (CLIENT-ARCHITECTURE §3):
/// a reused refresh token revokes the whole session, so two refreshes must never run at once.
public actor TokenStore {
    public typealias Refresher = @Sendable (_ refreshToken: String) async throws -> SessionTokens

    private let keychain: KeychainStore
    private var tokens: SessionTokens?
    private var inFlight: Task<SessionTokens, Error>?
    private var refresher: Refresher?

    private static let refreshAccount = "refresh_token"

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    public func setRefresher(_ refresher: @escaping Refresher) { self.refresher = refresher }

    /// True when a refresh token survives from a previous launch.
    public var hasStoredSession: Bool { keychain.read(Self.refreshAccount) != nil }

    public func store(_ tokens: SessionTokens) {
        keychain.write(tokens.refreshToken, for: Self.refreshAccount)
        self.tokens = tokens
    }

    public func clear() {
        inFlight?.cancel()
        inFlight = nil
        tokens = nil
        keychain.delete(Self.refreshAccount)
    }

    /// The current access token, refreshed first if it expires within 60 s.
    public func accessToken() async throws -> String? {
        if let tokens, tokens.expiresAt.timeIntervalSinceNow > 60 { return tokens.accessToken }
        guard tokens != nil || hasStoredSession else { return nil }
        return try await refresh().accessToken
    }

    /// Refreshes once, however many callers ask at the same moment.
    @discardableResult
    public func refresh() async throws -> SessionTokens {
        if let inFlight { return try await inFlight.value }
        guard let refresher, let refreshToken = tokens?.refreshToken ?? keychain.read(Self.refreshAccount) else {
            throw APIError.unauthenticated
        }
        let task = Task { try await refresher(refreshToken) }
        inFlight = task
        defer { inFlight = nil }
        do {
            let fresh = try await task.value
            store(fresh)
            return fresh
        } catch {
            if case APIError.unauthenticated = error { clear() }
            throw error
        }
    }
}
