import Foundation
import Testing
@testable import SubstratalCore

struct RouteTests {
    @Test func everyHubScreenHasAUniqueRoute() {
        let routes = ScreenID.allCases.map(\.info.route).filter { $0.hasPrefix("/") }
        #expect(Set(routes).count == routes.count)
        #expect(ScreenID.allCases.count == 75)
    }

    @Test func literalSegmentsBeatParameters() {
        #expect(Route.parse(path: "/admin/users/new")?.screen == .usr02)
        #expect(Route.parse(path: "/admin/users/usr_123")?.screen == .usr03)
        #expect(Route.parse(path: "/admin/users/usr_123")?["userId"] == "usr_123")
    }

    @Test func parsesUniversalLinksAndCustomScheme() {
        let universal = Route.parse(URL(string: "https://dashboard.substratalapps.com/dev/keys/key_ABC")!)
        #expect(universal == Route(.key04, ["keyId": "key_ABC"]))
        let custom = Route.parse(URL(string: "substratal://admin/audit")!)
        #expect(custom?.screen == .aud01)
        let emailed = Route.parse(URL(string: "https://dashboard.substratalapps.com/reset-password?token=pwr_1")!)
        #expect(emailed?.screen == .auth06)
        #expect(emailed?["token"] == "pwr_1")
    }

    @Test func ignoresForeignURLs() {
        #expect(Route.parse(URL(string: "https://example.com/admin/users")!) == nil)
    }

    @Test func rebuildsCanonicalPath() {
        #expect(Route(.apl07, ["appId": "app_hub"]).path == "/dev/apps/app_hub/push")
        #expect(Route(.app01).path == "/")
    }

    @Test func helpLinksAreStablePerScreen() {
        #expect(HelpCenter.url(for: .key03).absoluteString.hasSuffix("/help/screens/key-03.html"))
        #expect(HelpCenter.apiReference.absoluteString.hasSuffix("/help/api/v\(APIConfiguration.apiVersion)/"))
    }
}
