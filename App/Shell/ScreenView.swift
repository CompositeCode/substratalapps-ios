import SwiftUI
import SubstratalCore
import SubstratalUI

/// Maps a route to its screen. Screens that aren't built yet resolve to `ScreenPlaceholder`,
/// so all 75 routes and deep links work from the first build. Forbidden routes show the Forbidden state
/// rather than redirecting (INFORMATION-ARCHITECTURE §4).
struct ScreenView: View {
    let route: Route
    @Environment(SessionModel.self) private var session
    @Environment(\.palette) private var palette

    var body: some View {
        Group {
            if session.capabilities.shows(route.screen) {
                content
            } else {
                ErrorStateView(.forbidden(code: "forbidden"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { HelpButton(route.screen) }
        }
    }

    @ViewBuilder private var content: some View {
        switch route.screen {
        case .app01: HomeView()
        case .ntf01: InboxView()
        case .acc01: AccountView()
        case .set01: AppearanceSettingsView()
        case .glb02: ManageHubView()
        case .usr01: UsersView()
        case .usr03: UserDetailView(userID: route["userId"] ?? "")
        case .rol01: RolesView()
        case .rol02: RoleDetailView(roleID: route["roleId"] ?? "")
        case .aud01: AuditLogView()
        case .apl01: ApplicationsView()
        case .apl03: ApplicationDetailView(appID: route["appId"] ?? "")
        case .key01: APIKeysView()
        default: ScreenPlaceholder(route.screen, params: route.params)
        }
    }
}
