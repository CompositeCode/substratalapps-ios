import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Per-request values a screen sets for the duration of one call, without threading them through every API.
public enum RequestContext {
    /// Generated when a create form opens and reused on every retry of its submit (CLIENT-ARCHITECTURE §4).
    @TaskLocal public static var idempotencyKey: String?
    /// The `ETag` the screen loaded, sent as `If-Match` on PATCH/DELETE.
    @TaskLocal public static var ifMatch: String?
}

/// Adds `User-Agent`, `Accept-Language`, and any `RequestContext` values.
public struct RequestContextMiddleware: ClientMiddleware {
    let userAgent: String

    public init(userAgent: String) { self.userAgent = userAgent }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.userAgent] = userAgent
        request.headerFields[.acceptLanguage] = Locale.preferredLanguages.prefix(3).joined(separator: ", ")
        if let key = RequestContext.idempotencyKey { request.headerFields[.idempotencyKey] = key }
        if let etag = RequestContext.ifMatch { request.headerFields[.ifMatch] = etag }
        return try await next(request, body, baseURL)
    }
}
