import SwiftUI
import SubstratalCore
import SubstratalUI

/// APL-01 Applications.
struct ApplicationsView: View {
    @Environment(SessionModel.self) private var session
    @State private var state: LoadState<[ApplicationSummary]> = .idle

    var body: some View {
        LoadStateView(state, retry: { Task { await load() } }) { apps in
            List(apps) { app in
                NavigationLink(value: Route(.apl03, ["appId": app.id])) {
                    HStack(spacing: 12) {
                        AppIconPlaceholder(name: app.name)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(app.name).font(.body.weight(.medium))
                            HStack(spacing: 6) {
                                StatusBadge(app.reviewStatus)
                                Text("\(app.visibility) · \(app.accessTier)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .refreshable { await load() }
        }
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: Route(.apl02)) { Label("Register app", systemImage: "plus") }
                    .disabled(!(session.user?.emailVerified ?? false))
            }
        }
        .task { await load() }
    }

    private func load() async {
        do { state = .loaded(try await session.service.applications(cursor: nil).items) }
        catch let error as APIError { state = .failed(error) } catch {}
    }
}

/// APL-03 Application — Overview, with links to its tabs (settings schema, roles, push, keys, webhooks).
struct ApplicationDetailView: View {
    let appID: String
    @Environment(SessionModel.self) private var session
    @State private var app: ApplicationSummary?

    var body: some View {
        List {
            if let app {
                Section {
                    HStack(spacing: 12) {
                        AppIconPlaceholder(name: app.name)
                        VStack(alignment: .leading) {
                            Text(app.name).font(.title3.weight(.semibold))
                            StatusBadge(app.reviewStatus)
                        }
                    }
                    if let summary = app.summary { Text(summary).foregroundStyle(.secondary) }
                    IDChip(app.id)
                }
                Section("Catalog") {
                    LabeledContent("Slug", value: app.slug)
                    LabeledContent("Visibility", value: app.visibility.capitalized)
                    LabeledContent("Access tier", value: app.accessTier.capitalized)
                }
            }
            Section("Configure") {
                NavigationLink(value: Route(.apl04, ["appId": appID])) { Label("Settings schema", systemImage: "slider.horizontal.3") }
                NavigationLink(value: Route(.apl05, ["appId": appID])) { Label("Permissions & roles", systemImage: "checkmark.shield") }
                NavigationLink(value: Route(.apl07, ["appId": appID])) { Label("Push credentials", systemImage: "bell.badge") }
                if session.capabilities.canManageApplications {
                    NavigationLink(value: Route(.apl06, ["appId": appID])) { Label("Review", systemImage: "checkmark.seal") }
                }
            }
        }
        .navigationTitle(app?.name ?? "Application")
        .task { app = try? await session.service.applications(cursor: nil).items.first { $0.id == appID } }
    }
}
