import SwiftUI
import SubstratalCore
import SubstratalUI

/// Builds the object graph once per launch. Pass `-demo YES` (or pick "Demo data" on the sign-in screen
/// in debug builds) to run against fixtures with no network.
@MainActor
struct AppEnvironment {
    let configuration: APIConfiguration
    let session: SessionModel
    let versionMonitor: APIVersionMonitor
    let theme: ThemeStore
    let navigator: Navigator

    static func launch() -> AppEnvironment {
        let wantsDemo = UserDefaults.standard.bool(forKey: "demo") || ProcessInfo.processInfo.arguments.contains("-uiTesting")
        return make(wantsDemo ? .demo : .production)
    }

    static func make(_ environment: APIConfiguration.Environment) -> AppEnvironment {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let configuration = APIConfiguration.make(environment, appVersion: appVersion, osVersion: UIDevice.current.systemVersion)
        let monitor = APIVersionMonitor()
        let session: SessionModel
        switch environment {
        case .demo:
            session = SessionModel(service: DemoHubService(), tokens: nil)
        case .production, .localDevserver:
            let tokens = TokenStore()
            session = SessionModel(service: LiveHubService(configuration: configuration, tokens: tokens, versionMonitor: monitor), tokens: tokens)
        }
        return AppEnvironment(configuration: configuration, session: session, versionMonitor: monitor, theme: ThemeStore(), navigator: Navigator())
    }
}

private struct AppConfigurationKey: EnvironmentKey {
    static let defaultValue = APIConfiguration.make(.demo, appVersion: "0", osVersion: "0")
}

extension EnvironmentValues {
    var appConfiguration: APIConfiguration {
        get { self[AppConfigurationKey.self] }
        set { self[AppConfigurationKey.self] = newValue }
    }
}
