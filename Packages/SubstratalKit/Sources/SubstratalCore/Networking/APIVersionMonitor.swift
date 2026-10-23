import Foundation
import Observation

/// What the server has told this build about its API version (CLIENT-ARCHITECTURE §4.1).
public enum APIVersionState: Equatable, Sendable {
    /// The pinned version is current.
    case current
    /// The server sent `Deprecation` (RFC 9745) and usually `Sunset` (RFC 8594): show GLB-03 "Update available".
    case deprecated(sunset: Date?)
    /// The server answered `400 unsupported_api_version`: stop API traffic and show GLB-03 "Update required".
    case unsupported(supported: [String])
}

/// Collects version signals from every response. The UI observes `state`.
@MainActor @Observable
public final class APIVersionMonitor {
    public private(set) var state: APIVersionState = .current
    /// A response echoed a different version than the one sent: a proxy or misconfigured environment. Logged only.
    public private(set) var lastEchoMismatch: String?

    public init() {}

    public func recordDeprecation(sunset: Date?) {
        if case .unsupported = state { return }
        state = .deprecated(sunset: sunset)
    }

    public func recordUnsupported(supported: [String]) {
        state = .unsupported(supported: supported)
    }

    public func recordEcho(_ value: String) {
        if value != APIConfiguration.apiVersion { lastEchoMismatch = value }
    }

    /// Called on foreground with one fresh request, so a server-side fix clears "Update required".
    public func reset() { state = .current }
}
