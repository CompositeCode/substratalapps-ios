import Foundation

/// The API's error envelope: `{"error": {"code", "message", "details"}}` (Conventions → Errors).
public struct APIErrorEnvelope: Decodable, Sendable {
    public struct Body: Decodable, Sendable {
        public let code: String
        public let message: String
        public let details: Details?

        /// `details.supported` on `api_version_required` / `unsupported_api_version`.
        public var supportedVersions: [String]? { details?.supported }
    }

    public struct Details: Decodable, Sendable {
        public let supported: [String]?
        public let fields: [FieldError]?
    }

    public struct FieldError: Decodable, Sendable, Hashable {
        public let field: String
        public let code: String
    }

    public let error: Body
}

/// What screens see when a call fails. Copy for each case lives in COPY-AND-STATES.
public enum APIError: Error, Equatable, Sendable {
    case unauthenticated
    case forbidden(code: String)
    case notFound
    case conflict(code: String)
    case validation(fields: [APIErrorEnvelope.FieldError])
    case rateLimited(retryAfter: TimeInterval?)
    case notImplemented
    case unavailable
    case unsupportedAPIVersion
    case mfaRequired(mfaToken: String)
    case server(status: Int, code: String?, requestID: String?)
    case transport(String)

    public var userMessage: String {
        switch self {
        case .unauthenticated: "Your session has ended. Sign in again."
        case .forbidden: "You don't have permission to do that."
        case .notFound: "That item doesn't exist, or you can't see it."
        case .conflict(let code) where code == "version_conflict": "Someone else changed this while you were editing. Reload to see the latest."
        case .conflict: "That change conflicts with the current state."
        case .validation: "Some fields need attention."
        case .rateLimited: "Too many requests. Try again in a moment."
        case .notImplemented: "This feature isn't available yet."
        case .unavailable: "Substratal is temporarily unavailable."
        case .unsupportedAPIVersion: "Update the app to keep using Substratal."
        case .mfaRequired: "Enter your two-factor code."
        case .server: "Something went wrong on our side."
        case .transport: "You're offline or the connection failed."
        }
    }
}
