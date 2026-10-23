import Foundation
import HTTPTypes
import OpenAPIRuntime

extension HTTPField.Name {
    static let substratalVersion = HTTPField.Name(APIConfiguration.versionHeader)!
    static let deprecation = HTTPField.Name("Deprecation")!
    static let sunset = HTTPField.Name("Sunset")!
    static let requestID = HTTPField.Name("X-Request-Id")!
    static let idempotencyKey = HTTPField.Name("Idempotency-Key")!
    static let ifMatch = HTTPField.Name("If-Match")!
}

/// Sends `Substratal-Version` on every request and watches responses for version signals.
///
/// The generated client never sets the header itself: scripts/sync-openapi.sh strips the per-operation
/// `ApiVersion` parameter so this middleware is the single place the version is chosen.
/// Exempt endpoints (`GET /health`, `POST /auth/oauth/token`, `/.well-known/*`) accept the header harmlessly.
public struct APIVersionMiddleware: ClientMiddleware {
    let monitor: APIVersionMonitor

    public init(monitor: APIVersionMonitor) { self.monitor = monitor }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.substratalVersion] = APIConfiguration.apiVersion
        let (response, responseBody) = try await next(request, body, baseURL)

        if let echo = response.headerFields[.substratalVersion] {
            await monitor.recordEcho(echo)
        }
        if response.headerFields[.deprecation] != nil {
            let sunset = response.headerFields[.sunset].flatMap(HTTPDate.parse)
            await monitor.recordDeprecation(sunset: sunset)
        }
        guard response.status.code == 400, let responseBody else { return (response, responseBody) }

        // Read the (small) error body to tell `unsupported_api_version` apart, then hand it back unchanged.
        let data = try await Data(collecting: responseBody, upTo: 64 * 1024)
        if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data),
           envelope.error.code == "unsupported_api_version" {
            await monitor.recordUnsupported(supported: envelope.error.supportedVersions ?? [])
        }
        return (response, HTTPBody(data))
    }
}

/// RFC 9110 IMF-fixdate, as used by the `Sunset` header.
enum HTTPDate {
    static func parse(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: value)
    }
}
