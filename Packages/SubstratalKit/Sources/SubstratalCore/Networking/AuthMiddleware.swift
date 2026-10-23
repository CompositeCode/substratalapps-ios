import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Adds the Bearer token, and on `401` refreshes once (single-flight) and replays the request.
public struct AuthMiddleware: ClientMiddleware {
    let tokens: TokenStore

    public init(tokens: TokenStore) { self.tokens = tokens }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var authorized = request
        if let token = try await tokens.accessToken() {
            authorized.headerFields[.authorization] = "Bearer \(token)"
        }
        // Buffer the body so the request can be replayed after a refresh.
        let buffered: HTTPBody? = if let body { HTTPBody(try await Data(collecting: body, upTo: 4 * 1024 * 1024)) } else { nil }
        let (response, responseBody) = try await next(authorized, buffered, baseURL)
        guard response.status == .unauthorized else { return (response, responseBody) }

        let fresh = try await tokens.refresh()
        var retried = request
        retried.headerFields[.authorization] = "Bearer \(fresh.accessToken)"
        return try await next(retried, buffered, baseURL)
    }
}
