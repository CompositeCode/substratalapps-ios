import SwiftUI
import SubstratalCore
import SubstratalUI

/// ROL-01 Roles (platform scope in MVP).
struct RolesView: View {
    @Environment(SessionModel.self) private var session
    @State private var state: LoadState<[RoleSummary]> = .idle

    var body: some View {
        LoadStateView(state, retry: { Task { await load() } }) { roles in
            List(roles) { role in
                NavigationLink(value: Route(.rol02, ["roleId": role.id])) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(role.name).font(.body.weight(.medium))
                            if role.seed { StatusBadge(.none, label: "Built-in") }
                        }
                        Text("\(role.permissions.count) permissions · \(role.assignmentCount) people")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .refreshable { await load() }
        }
        .navigationTitle("Roles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: Route(.rol03)) { Label("New role", systemImage: "plus") }
                    .disabled(!session.capabilities.canManageRoles)
            }
        }
        .task { await load() }
    }

    private func load() async {
        do { state = .loaded(try await session.service.roles(scope: "platform")) }
        catch let error as APIError { state = .failed(error) } catch {}
    }
}

/// ROL-02 Role detail: the permission checklist. Built-in (seed) roles are read-only.
struct RoleDetailView: View {
    let roleID: String
    @Environment(SessionModel.self) private var session
    @State private var role: RoleSummary?

    var body: some View {
        List {
            if let role {
                Section {
                    LabeledContent("Scope", value: role.scope)
                    LabeledContent("People", value: "\(role.assignmentCount)")
                    if let description = role.description { Text(description).foregroundStyle(.secondary) }
                    IDChip(role.id)
                } footer: {
                    if role.seed { Text("Seed roles can't be edited.") }
                }
                Section("Permissions") {
                    if role.permissions.isEmpty { Text("None").foregroundStyle(.secondary) }
                    ForEach(role.permissions, id: \.self) { Label($0, systemImage: "checkmark").font(.body.monospaced()) }
                }
                Section {
                    NavigationLink("People with this role", value: Route(.usr01, ["role_id": role.id]))
                }
            }
        }
        .navigationTitle(role?.name ?? "Role")
        .task { role = try? await session.service.roles(scope: nil).first { $0.id == roleID } }
    }
}
