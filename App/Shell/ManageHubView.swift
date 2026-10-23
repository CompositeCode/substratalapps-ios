import SwiftUI
import SubstratalCore
import SubstratalUI

/// GLB-02 Manage hub: the compact layout's entry to Administration and Developer.
/// Sections the person can't use are hidden, never shown disabled.
struct ManageHubView: View {
    @Environment(SessionModel.self) private var session

    var body: some View {
        let caps = session.capabilities
        List {
            let admin = HubSection.administration.filter { $0.isVisible(for: caps) }
            if !admin.isEmpty {
                Section("Administration") {
                    ForEach(admin) { section in
                        NavigationLink(value: Route(section.root)) { Label(section.title, systemImage: section.symbol) }
                    }
                }
            }
            let developer = HubSection.developer.filter { $0.isVisible(for: caps) }
            if !developer.isEmpty {
                Section("Developer") {
                    ForEach(developer) { section in
                        NavigationLink(value: Route(section.root)) { Label(section.title, systemImage: section.symbol) }
                    }
                }
            }
        }
        .navigationTitle("Manage")
    }
}
