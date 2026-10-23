import Testing
@testable import SubstratalCore

struct ModelTests {
    @Test func unknownEnumValuesDegradeGracefully() {
        let status = StatusKind(rawValue: "quarantined")
        #expect(status == .unknown("quarantined"))
        #expect(status.role == .neutral)
        #expect(status.label == "Quarantined")
    }

    @Test func reviewStatusMapping() {
        #expect(StatusKind.applicationReview("pending_review") == .pending)
        #expect(StatusKind.applicationReview("rejected") == .revoked)
    }

    @Test func manageTabHiddenForEndUsers() {
        #expect(!Capabilities.none.showsManage)
        #expect(Capabilities(ownedApplicationIDs: ["app_x"]).showsManage)
        #expect(Capabilities.superadmin.showsAdministration && Capabilities.superadmin.showsDeveloper)
        #expect(!Capabilities(platformPermissions: ["users.list"]).shows(.aud01))
    }
}
