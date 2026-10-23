import SwiftUI
import SubstratalCore
import SubstratalUI

/// APP-01 Home — My Apps. Internal apps (like the Hub itself) never show as tiles.
struct HomeView: View {
    @Environment(SessionModel.self) private var session
    @Environment(\.palette) private var palette
    @State private var state: LoadState<[ApplicationSummary]> = .idle

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        LoadStateView(state, retry: load) { apps in
            ScrollView {
                if apps.isEmpty {
                    ContentUnavailableView("No apps yet", systemImage: "square.grid.2x2", description: Text("Apps you have access to appear here."))
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(apps) { app in
                            NavigationLink(value: Route(.app02, ["appId": app.id])) { AppTile(app: app) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .refreshable { await reload() }
        }
        .background(palette.background)
        .navigationTitle("Home")
        .task { if case .idle = state { load() } }
    }

    private func load() { Task { await reload() } }

    private func reload() async {
        if state.value == nil { state = .loading }
        do {
            let page = try await session.service.applications(cursor: nil)
            state = .loaded(page.items.filter { $0.visibility != "internal" })
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.transport(error.localizedDescription))
        }
    }
}

private struct AppTile: View {
    let app: ApplicationSummary
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppIconPlaceholder(name: app.name)
            Text(app.name).font(.headline).foregroundStyle(palette.text)
            Text(app.summary ?? "").font(.caption).foregroundStyle(palette.textSecondary).lineLimit(2, reservesSpace: true)
            Text(app.accessTier == "free" ? "Free" : "Standard").font(.caption2.weight(.semibold)).foregroundStyle(palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(palette.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows app info")
    }
}
