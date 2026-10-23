import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Turns every non-2xx response into an `APIError`, decoded from the API's error envelope,
/// so services only ever handle the success case of a generated `Output`.
public struct ErrorMappingMiddleware: ClientMiddleware {
    public init() {}

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let (response, responseBody) = try await next(request, body, baseURL)
        guard response.status.kind != .successful else { return (response, responseBody) }

        let data = if let responseBody { try await Data(collecting: responseBody, upTo: 256 * 1024) } else { Data() }
        let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data)
        let code = envelope?.error.code
        let requestID = response.headerFields[.requestID]

        switch response.status.code {
        case 400 where code == "unsupported_api_version": throw APIError.unsupportedAPIVersion
        case 401: throw APIError.unauthenticated
        case 403: throw APIError.forbidden(code: code ?? "forbidden")
        case 404: throw APIError.notFound
        case 409: throw APIError.conflict(code: code ?? "conflict")
        case 422: throw APIError.validation(fields: envelope?.error.details?.fields ?? [])
        case 429: throw APIError.rateLimited(retryAfter: response.headerFields[.retryAfter].flatMap(TimeInterval.init))
        case 501: throw APIError.notImplemented
        case 503: throw APIError.unavailable
        default: throw APIError.server(status: response.status.code, code: code, requestID: requestID)
        }
    }
}

/// Unwraps the generator's `ClientError` so callers see the `APIError` a middleware threw.
func unwrapping<T: Sendable>(_ body: () async throws -> T) async throws -> T {
    do {
        return try await body()
    } catch let error as ClientError {
        if let apiError = error.underlyingError as? APIError { throw apiError }
        throw APIError.transport(error.underlyingError.localizedDescription)
    }
}
