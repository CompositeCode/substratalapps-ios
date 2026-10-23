import SwiftUI
import SubstratalCore
import SubstratalUI

/// KEY-01 API keys. The app never holds an API key: people manage keys with their own session,
/// and a new key's secret is shown once (KEY-03), then exists only where the person stored it.
struct APIKeysView: View {
    @Environment(SessionModel.self) private var session
    @State private var keys: LoadState<[APIKeySummary]> = .idle
    @State private var includeInactive = false
    @State private var creating = false
    @State private var revealed: CreatedAPIKey?
    @State private var pendingRevoke: APIKeySummary?

    var body: some View {
        LoadStateView(keys, retry: { Task { await load() } }) { keys in
            List {
                Section {
                    Toggle("Show revoked and expired", isOn: $includeInactive)
                }
                Section {
                    ForEach(keys) { key in
                        APIKeyRow(key: key)
                            .swipeActions(edge: .trailing) {
                                if key.status == .active {
                                    Button("Revoke", role: .destructive) { pendingRevoke = key }
                                }
                            }
                    }
                }
            }
            .refreshable { await load() }
        }
        .navigationTitle("API Keys")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Create key", systemImage: "plus") { creating = true }
            }
        }
        .task(id: includeInactive) { await load() }
        .sheet(isPresented: $creating) {
            CreateAPIKeyView { created in
                creating = false
                revealed = created
            }
        }
        .sheet(item: $revealed) { created in
            SecretRevealSheet(title: created.key.name, secret: created.secret,
                              note: "Use it as a Bearer token from your server. API keys never belong in an app or a browser; the API refuses them there.") {
                revealed = nil
                Task { await load() }
            }
        }
        .confirmationDialog("Revoke \(pendingRevoke?.name ?? "")?", isPresented: Binding(get: { pendingRevoke != nil }, set: { if !$0 { pendingRevoke = nil } }), titleVisibility: .visible, presenting: pendingRevoke) { key in
            Button("Revoke key", role: .destructive) {
                Task {
                    try? await session.service.revokeAPIKey(id: key.id)
                    await load()
                }
            }
        } message: { _ in
            Text("Anything using this key stops working immediately. This can't be undone.")
        }
    }

    private func load() async {
        do { keys = .loaded(try await session.service.apiKeys(includeInactive: includeInactive, cursor: nil).items) }
        catch let error as APIError { keys = .failed(error) } catch {}
    }
}

extension CreatedAPIKey: @retroactive Identifiable {
    public var id: String { key.id }
}

private struct APIKeyRow: View {
    let key: APIKeySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(key.name).font(.body.weight(.medium))
                if key.mode == "test" { StatusBadge(.scheduled, label: "TEST") }
                if key.intendedUse == "agent" { StatusBadge(.pending, label: key.restrictDestructive ? "Agent · safe" : "Agent") }
            }
            HStack(spacing: 6) {
                StatusBadge(key.status)
                Text(key.scope == "platform" ? "Platform" : key.scope).font(.caption.monospaced()).foregroundStyle(.secondary)
                if let hint = key.secretHint { Text(hint).font(.caption.monospaced()).foregroundStyle(.secondary) }
            }
            Group {
                if let used = key.lastUsedAt { Text("Last used \(used, format: .relative(presentation: .named))") } else { Text("Never used") }
            }
            .font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// KEY-02 Create API key.
struct CreateAPIKeyView: View {
    let onCreated: (CreatedAPIKey) -> Void
    @Environment(SessionModel.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var draft = NewAPIKey()
    @State private var catalog: [String] = []
    @State private var expires = true
    @State private var error: APIError?
    @State private var saving = false
    /// Generated when the form opens and reused on every retry (CLIENT-ARCHITECTURE §4).
    @State private var idempotencyKey = UUID().uuidString

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.name, prompt: Text("billing-webhook-handler"))
                        .textInputAutocapitalization(.never)
                    TextField("Scope", text: $draft.scope, prompt: Text("platform or app_…"))
                        .textInputAutocapitalization(.never)
                        .font(.body.monospaced())
                } footer: {
                    Text("A platform key needs api_keys.manage, and can't hold more than you do. An app key can only reach its own Application.")
                }
                Section("Mode and use") {
                    Picker("Mode", selection: $draft.mode) {
                        Text("Live").tag("live")
                        Text("Test").tag("test")
                    }
                    Picker("Intended use", selection: $draft.intendedUse) {
                        Text("Service").tag("service")
                        Text("AI agent").tag("agent")
                    }
                    if draft.intendedUse == "agent" {
                        Label("Agent keys can't run destructive operations unless you turn that on later.", systemImage: "shield.lefthalf.filled")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Expiry") {
                    Toggle("Expires", isOn: $expires)
                    if expires {
                        DatePicker("Expires on", selection: Binding(get: { draft.expiresAt ?? .now }, set: { draft.expiresAt = $0 }),
                                   in: Date.now..., displayedComponents: .date)
                    }
                }
                Section("Permissions") {
                    ForEach(catalog, id: \.self) { permission in
                        Toggle(permission, isOn: Binding(
                            get: { draft.permissions.contains(permission) },
                            set: { isOn in
                                if isOn { draft.permissions.insert(permission) } else { draft.permissions.remove(permission) }
                            }
                        ))
                        .font(.callout.monospaced())
                    }
                }
                if let error {
                    Section { Label(error.userMessage, systemImage: "exclamationmark.circle").foregroundStyle(Color.danger) }
                }
            }
            .navigationTitle("Create API key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(draft.name.isEmpty || draft.scope.isEmpty || draft.permissions.isEmpty || saving)
                }
            }
            .task { catalog = (try? await session.service.permissionCatalog()) ?? [] }
        }
    }

    private func create() {
        saving = true
        if !expires { draft.expiresAt = nil }
        Task {
            defer { saving = false }
            do { onCreated(try await session.service.createAPIKey(draft, idempotencyKey: idempotencyKey)) }
            catch let failure as APIError { error = failure } catch {}
        }
    }
}
