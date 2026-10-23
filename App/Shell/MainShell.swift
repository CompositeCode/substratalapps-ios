import SwiftUI
import SubstratalCore
import SubstratalUI

/// iPhone: five tabs, Administration + Developer combined under Manage (GLB-02), Manage removed when the
/// person has no rights there. iPad (regular width, iOS 18+): a sidebar-adaptable TabView showing the full tree.
struct MainShell: View {
    @Environment(SessionModel.self) private var session
    @Environment(Navigator.self) private var navigator
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular, #available(iOS 18.0, *) {
                SidebarShell()
            } else {
                CompactShell()
            }
        }
        .onAppear { navigator.shellAppeared(compact: sizeClass != .regular) }
        .onDisappear { navigator.shellDisappeared() }
        .onChange(of: sizeClass) { _, value in navigator.layoutChanged(compact: value != .regular) }
    }
}

private struct CompactShell: View {
    @Environment(SessionModel.self) private var session
    @Environment(Navigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        TabView(selection: $navigator.selection) {
            ForEach(HubSection.compactTabs.filter { $0.isVisible(for: session.capabilities) }) { section in
                SectionStack(section: section)
                    .tabItem { Label(section.compactTitle, systemImage: section.symbol) }
                    .tag(section)
            }
        }
    }
}

@available(iOS 18.0, *)
private struct SidebarShell: View {
    @Environment(SessionModel.self) private var session
    @Environment(Navigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        let caps = session.capabilities
        TabView(selection: $navigator.selection) {
            ForEach(HubSection.personal) { section in
                Tab(section.title, systemImage: section.symbol, value: section) { SectionStack(section: section) }
            }
            if caps.showsAdministration {
                TabSection("Administration") {
                    ForEach(HubSection.administration.filter { $0.isVisible(for: caps) }) { section in
                        Tab(section.title, systemImage: section.symbol, value: section) { SectionStack(section: section) }
                    }
                }
            }
            if caps.showsDeveloper {
                TabSection("Developer") {
                    ForEach(HubSection.developer.filter { $0.isVisible(for: caps) }) { section in
                        Tab(section.title, systemImage: section.symbol, value: section) { SectionStack(section: section) }
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

/// One NavigationStack per section, its path owned by the Navigator so deep links can rewrite it.
struct SectionStack: View {
    let section: HubSection
    @Environment(Navigator.self) private var navigator

    var body: some View {
        NavigationStack(path: navigator.path(for: section)) {
            ScreenView(route: Route(section.root))
                .navigationDestination(for: Route.self) { ScreenView(route: $0) }
        }
    }
}
