import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
@testable import SubstratalCore

struct VersioningTests {
    @Test func baseURLHasNoVersionPrefix() {
        let config = APIConfiguration.make(.production, appVersion: "1", osVersion: "26")
        #expect(config.baseURL.absoluteString == "https://api.substratalapps.com")
        #expect(!config.baseURL.path.contains("v1"))
    }

    /// The pinned header value must be one the vendored contract declares (api-contract/CONTRACT.json).
    @Test func pinnedVersionIsDeclaredByTheContract() throws {
        let contract = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "api-contract/CONTRACT.json")
        struct Record: Decodable { let substratal_versions: [String]; let info_version: String }
        let record = try JSONDecoder().decode(Record.self, from: Data(contentsOf: contract))
        #expect(record.substratal_versions.contains(APIConfiguration.apiVersion))
        #expect(record.info_version == contractVersion)
    }

    @Test @MainActor func middlewareSendsHeaderAndRecordsDeprecation() async throws {
        let monitor = APIVersionMonitor()
        let middleware = APIVersionMiddleware(monitor: monitor)
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.substratalapps.com", path: "/users")
        let (response, _) = try await middleware.intercept(request, body: nil, baseURL: URL(string: "https://api.substratalapps.com")!, operationID: "users.list") { sent, _, _ in
            #expect(sent.headerFields[HTTPField.Name("Substratal-Version")!] == "1")
            var fields = HTTPFields()
            fields[HTTPField.Name("Substratal-Version")!] = "1"
            fields[HTTPField.Name("Deprecation")!] = "@1798761600"
            fields[HTTPField.Name("Sunset")!] = "Sat, 01 May 2027 00:00:00 GMT"
            return (HTTPResponse(status: .ok, headerFields: fields), nil)
        }
        #expect(response.status == .ok)
        guard case .deprecated(let sunset) = monitor.state else { Issue.record("expected deprecated"); return }
        #expect(sunset != nil)
    }

    @Test @MainActor func unsupportedVersionBlocksTheApp() async throws {
        let monitor = APIVersionMonitor()
        let middleware = APIVersionMiddleware(monitor: monitor)
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.substratalapps.com", path: "/users")
        let body = #"{"error":{"code":"unsupported_api_version","message":"x","details":{"supported":["2"]}}}"#
        _ = try await middleware.intercept(request, body: nil, baseURL: URL(string: "https://api.substratalapps.com")!, operationID: "users.list") { _, _, _ in
            (HTTPResponse(status: .badRequest), HTTPBody(body))
        }
        #expect(monitor.state == .unsupported(supported: ["2"]))
    }
}
