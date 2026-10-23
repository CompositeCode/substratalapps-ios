import Foundation

/// Where the Hub talks to and which API version it was built against.
///
/// The Platform API serves every path at the host root. There is no `/v1` in any URL;
/// the version travels in the `Substratal-Version` request header instead
/// (CLIENT-ARCHITECTURE §4.1, API Conventions → Versioning). `/v1/…` paths return `404 not_found`.
public struct APIConfiguration: Sendable, Hashable {
    /// The API version this build is written against. Pinned per build, never negotiated at runtime.
    public static let apiVersion = "1"
    /// The request and response header that carries the API version.
    public static let versionHeader = "Substratal-Version"

    public enum Environment: String, Sendable, CaseIterable, Identifiable {
        case production
        case localDevserver
        case demo

        public var id: String { rawValue }
        public var displayName: String {
            switch self {
            case .production: "Production"
            case .localDevserver: "Local devserver"
            case .demo: "Demo data (offline)"
            }
        }
    }

    public var environment: Environment
    /// Host-root base URL, e.g. `https://api.substratalapps.com`. Never ends in a version segment.
    public var baseURL: URL
    /// Sent as `User-Agent` so Sessions (ACC-04, USR-04) can name this device.
    public var userAgent: String

    public init(environment: Environment, baseURL: URL, userAgent: String) {
        precondition(!baseURL.path.hasPrefix("/v1"), "The Platform API has no /v1 prefix; the version goes in the Substratal-Version header.")
        self.environment = environment
        self.baseURL = baseURL
        self.userAgent = userAgent
    }

    public static func make(_ environment: Environment, appVersion: String, osVersion: String) -> APIConfiguration {
        let url: URL = switch environment {
        case .production, .demo: URL(string: "https://api.substratalapps.com")!
        case .localDevserver: URL(string: "http://localhost:8080")!
        }
        return APIConfiguration(environment: environment, baseURL: url, userAgent: "Substratal-iOS/\(appVersion) (iOS \(osVersion))")
    }
}
