import SwiftUI
import SubstratalCore
import SubstratalUI

@main
struct SubstratalHubApp: App {
    @State private var environment = AppEnvironment.launch()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment.session)
                .environment(environment.versionMonitor)
                .environment(environment.theme)
                .environment(environment.navigator)
                .environment(\.appConfiguration, environment.configuration)
                .substratalTheme(environment.theme)
                .onOpenURL { environment.navigator.open($0) }
        }
    }
}
