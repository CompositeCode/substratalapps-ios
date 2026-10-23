import SwiftUI
import SubstratalCore

/// Owns the selected section and one navigation path per section, and routes deep links
/// (Universal Links, `substratal://`, notification `action_url`s) into them (INFORMATION-ARCHITECTURE §4).
@MainActor @Observable
final class Navigator {
    var selection: HubSection = .home
    var paths: [HubSection: [Route]] = [:]
    var isCompact = true
    /// A link that arrived before the shell existed (signed out, restoring); replayed by `shellAppeared`.
    private(set) var pending: Route?
    private var isShellReady = false

    func path(for section: HubSection) -> Binding<[Route]> {
        Binding(get: { self.paths[section, default: []] }, set: { self.paths[section] = $0 })
    }

    func push(_ route: Route) {
        paths[selection, default: []].append(route)
    }

    func open(_ url: URL) {
        guard let route = Route.parse(url) else {
            UIApplication.shared.open(url)
            return
        }
        open(route)
    }

    /// Called by the shell once it knows its layout. Replays a deferred deep link.
    func shellAppeared(compact: Bool) {
        isShellReady = true
        layoutChanged(compact: compact)
        if let pending {
            self.pending = nil
            open(pending)
        }
    }

    func shellDisappeared() { isShellReady = false }

    /// Keeps the selection valid when an iPad moves between compact (tabs + Manage) and regular (sidebar).
    func layoutChanged(compact: Bool) {
        isCompact = compact
        if compact, selection.group != .personal || selection == .billing || selection == .settings {
            selection = HubSection.owning(selection.root, compact: true)
        } else if !compact, selection == .manage {
            selection = .users
        }
    }

    func open(_ route: Route) {
        guard isShellReady else {
            pending = route
            return
        }
        let section = HubSection.owning(route.screen, compact: isCompact)
        let inner = HubSection.owning(route.screen, compact: false)
        selection = section
        if route.screen == section.root {
            paths[section] = []
        } else if section != inner, inner.root != route.screen {
            // Compact: Administration/Developer screens sit under the Manage hub, behind their section's root.
            paths[section] = [Route(inner.root), route]
        } else {
            paths[section] = [route]
        }
    }
}
