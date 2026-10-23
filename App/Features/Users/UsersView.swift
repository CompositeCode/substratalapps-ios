import SwiftUI
import SubstratalCore
import SubstratalUI

/// USR-01 Users: search, status filter, cursor pagination.
struct UsersView: View {
    @Environment(SessionModel.self) private var session
    @State private var query = UserQuery()
    @State private var users: [UserSummary] = []
    @State private var nextCursor: String?
    @State private var error: APIError?
    @State private var loading = false

    private let statuses: [(String?, String)] = [(nil, "All"), ("active", "Active"), ("invited", "Invited"), ("suspended", "Suspended")]

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(statuses, id: \.1) { status, label in
                            Button(label) { query.status = status }
                                .buttonStyle(.bordered)
                                .tint(query.status == status ? .accentColor : .secondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            Section {
                ForEach(users) { user in
                    NavigationLink(value: Route(.usr03, ["userId": user.id])) { UserRow(user: user) }
                }
                if nextCursor != nil {
                    ProgressView().frame(maxWidth: .infinity).task { await load(more: true) }
                }
            }
        }
        .overlay {
            if let error, users.isEmpty { ErrorStateView(error) { Task { await load() } } }
            else if !loading, users.isEmpty { ContentUnavailableView.search(text: query.text) }
        }
        .searchable(text: $query.text, prompt: "Email, name or usr_ ID")
        .refreshable { await load() }
        .task(id: query) { await load() }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: Route(.usr02)) { Label("Invite user", systemImage: "person.badge.plus") }
                    .disabled(!session.capabilities.canManageUsers)
            }
        }
    }

    private func load(more: Bool = false) async {
        loading = true
        defer { loading = false }
        do {
            let page = try await session.service.users(query, cursor: more ? nextCursor : nil)
            users = more ? users + page.items : page.items
            nextCursor = page.nextCursor
            error = nil
        } catch let failure as APIError {
            error = failure
        } catch {}
    }
}

struct UserRow: View {
    let user: UserSummary

    var body: some View {
        HStack(spacing: 12) {
            Text(user.initials)
                .font(.subheadline.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(.tint.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(user.email).lineLimit(1)
                HStack(spacing: 6) {
                    StatusBadge(user.status)
                    if user.testMode { StatusBadge(.scheduled, label: "TEST") }
                    if let last = user.lastLoginAt {
                        Text(last, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// USR-03 User — Overview, with the spec's tabs as a segmented control (Overview · Access · Roles · Sessions · Notifications).
struct UserDetailView: View {
    let userID: String
    @Environment(SessionModel.self) private var session
    @State private var user: LoadState<UserSummary> = .idle
    @State private var access: [AccessSummary] = []
    @State private var tab: Tab = .overview
    @State private var pendingTurnOff: AccessSummary?

    enum Tab: String, CaseIterable { case overview = "Overview", access = "Access", roles = "Roles", sessions = "Sessions", notifications = "Notifications" }

    var body: some View {
        LoadStateView(user, retry: { Task { await load() } }) { user in
            List {
                Section {
                    UserRow(user: user)
                    IDChip(user.id)
                    Picker("Section", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                switch tab {
                case .overview: overview(user)
                case .access: accessSection
                case .roles: link("Roles", .rol04)
                case .sessions: link("Sessions", .usr04)
                case .notifications: link("Notifications & devices", .ntf05)
                }
            }
            .navigationTitle(user.email)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    NavigationLink(value: Route(.usr05, ["userId": userID])) { Label("Suspend…", systemImage: "pause.circle") }
                        .disabled(!session.capabilities.canManageUsers)
                }
            }
        }
        .task { await load() }
        .confirmationDialog("Turn off \(pendingTurnOff?.applicationName ?? "")?", isPresented: Binding(get: { pendingTurnOff != nil }, set: { if !$0 { pendingTurnOff = nil } }), titleVisibility: .visible, presenting: pendingTurnOff) { _ in
            Button("Turn off", role: .destructive) { pendingTurnOff = nil }
            Button("Cancel", role: .cancel) { pendingTurnOff = nil }
        } message: { _ in
            Text("They lose access right away. Their roles and settings are kept, so turning it back on restores everything.")
        }
    }

    @ViewBuilder private func overview(_ user: UserSummary) -> some View {
        Section("Account") {
            LabeledContent("Email verified", value: user.emailVerified ? "Yes" : "No")
            LabeledContent("Two-factor", value: user.mfaEnabled ? "On" : "Off")
            LabeledContent("Plan", value: (user.plan ?? "free").capitalized)
            if let created = user.createdAt { LabeledContent("Joined") { Text(created, style: .date) } }
            if let expires = user.expiresAt { LabeledContent("Test user expires") { Text(expires, style: .relative) } }
        }
        Section("Activity") {
            NavigationLink(value: Route(.aud01, ["target_user_id": userID])) { Label("Audit trail", systemImage: "list.bullet.clipboard") }
        }
    }

    @ViewBuilder private var accessSection: some View {
        Section {
            ForEach(access) { row in
                AccessRow(row) { on in if !on { pendingTurnOff = row } }
            }
        } header: {
            Text("Apps")
        } footer: {
            Text("Status shows the resolved access. Tap an app for every path that grants it.")
        }
        Section {
            NavigationLink(value: Route(.acx02, ["userId": userID])) { Label("Grant access", systemImage: "plus.circle") }
        }
    }

    private func link(_ title: String, _ screen: ScreenID) -> some View {
        Section { NavigationLink(title, value: Route(screen, ["userId": userID])) }
    }

    private func load() async {
        do {
            async let detail = session.service.user(id: userID)
            async let rows = session.service.access(userID: userID)
            user = .loaded(try await detail)
            access = (try? await rows) ?? []
        } catch let error as APIError {
            user = .failed(error)
        } catch {}
    }
}
