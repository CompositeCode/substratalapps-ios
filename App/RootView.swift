import SwiftUI
import SubstratalCore
import SubstratalUI

/// Auth gate: restoring → sign-in / two-factor → the shell. "Update required" blocks everything.
struct RootView: View {
    @Environment(\.appConfiguration) private var configuration
    @Environment(SessionModel.self) private var session
    @Environment(APIVersionMonitor.self) private var versionMonitor
    @Environment(Navigator.self) private var navigator
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if case .unsupported(let supported) = versionMonitor.state {
                UpdateRequiredView(supported: supported) {
                    versionMonitor.reset()
                    Task { await session.refreshCapabilities() }
                }
            } else {
                switch session.phase {
                case .restoring:
                    ProgressView().controlSize(.large)
                case .signedOut:
                    SignInView()
                case .awaitingMFA:
                    TwoFactorView()
                case .signedIn:
                    MainShell()
                        .safeAreaInset(edge: .top) { APIVersionBanner(versionMonitor.state) }
                }
            }
        }
        .animation(.default, value: session.phase)
        .task {
            await session.restore()
            await applyDemoLaunchArguments()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, session.phase == .signedIn { Task { await session.refreshCapabilities() } }
        }
    }

    /// Demo-only conveniences for screenshots and UI tests: `-autoSignIn YES` skips AUTH-01/02,
    /// and `-route /admin/users` opens a route as if it arrived as a deep link.
    private func applyDemoLaunchArguments() async {
        guard configuration.environment == .demo else { return }
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "autoSignIn"), session.phase == .signedOut {
            await session.signIn(email: "adron@substratalapps.com", password: "demo")
            await session.verifyMFA(code: "000000")
        }
        if let path = defaults.string(forKey: "route"), let route = Route.parse(path: path) {
            navigator.open(route)
        }
    }
}
