import SwiftUI
import SubstratalCore
import SubstratalUI

/// ACC-01 Account & profile, plus the compact layout's home for Plan & Billing, Settings and Help.
struct AccountView: View {
    @Environment(SessionModel.self) private var session
    @Environment(\.appConfiguration) private var configuration
    @Environment(\.openURL) private var openURL
    @State private var confirmSignOutEverywhere = false

    var body: some View {
        List {
            if let user = session.user {
                Section {
                    HStack(spacing: 14) {
                        Text(user.initials)
                            .font(.title3.weight(.semibold))
                            .frame(width: 52, height: 52)
                            .background(.tint.opacity(0.15), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.email).font(.headline)
                            HStack {
                                StatusBadge(user.plan == "standard" ? .active : .none, label: user.plan == "standard" ? "Standard" : "Free")
                                if user.mfaEnabled { StatusBadge(.active, label: "Two-factor on") }
                            }
                        }
                    }
                    IDChip(user.id)
                }
            }
            Section {
                NavigationLink(value: Route(.acc04)) { Label("Security", systemImage: "lock.shield") }
                NavigationLink(value: Route(.ntf03)) { Label("Devices & notifications", systemImage: "iphone.gen3") }
                NavigationLink(value: Route(.acc07)) { Label("Privacy", systemImage: "hand.raised") }
            }
            Section {
                NavigationLink(value: Route(.bil01)) { Label("Plan & Billing", systemImage: "creditcard") }
                NavigationLink(value: Route(.set01)) { Label("Settings", systemImage: "gearshape") }
            }
            Section("Help & documentation") {
                Button { openURL(HelpCenter.home) } label: { Label("Help center", systemImage: "questionmark.circle") }
                Button { openURL(HelpCenter.tutorials) } label: { Label("Tutorials", systemImage: "graduationcap") }
                Button { openURL(HelpCenter.faq) } label: { Label("FAQ", systemImage: "text.bubble") }
                Button { openURL(HelpCenter.apiReference) } label: { Label("API reference (v\(APIConfiguration.apiVersion))", systemImage: "curlybraces") }
                Button { openURL(HelpCenter.whatsNew) } label: { Label("What's new", systemImage: "sparkles") }
            }
            Section("About") {
                LabeledContent("App version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–")
                LabeledContent("API", value: configuration.baseURL.host() ?? "")
                LabeledContent("API version (Substratal-Version)", value: APIConfiguration.apiVersion)
                LabeledContent("Contract", value: SubstratalCore.contractVersion)
            }
            Section {
                Button("Sign out", role: .destructive) { Task { await session.signOut() } }
                Button("Sign out everywhere…", role: .destructive) { confirmSignOutEverywhere = true }
            }
        }
        .navigationTitle("Account")
        .confirmationDialog("Sign out on every device?", isPresented: $confirmSignOutEverywhere, titleVisibility: .visible) {
            Button("Sign out everywhere", role: .destructive) { Task { await session.signOut(everywhere: true) } }
        } message: {
            Text("Every session you have, on every device, ends now.")
        }
    }
}

/// SET-01 Settings — Global: appearance and theme choice (THEMES.md). Other settings rows come with the full screen.
struct AppearanceSettingsView: View {
    @Environment(ThemeStore.self) private var theme

    var body: some View {
        @Bindable var theme = theme
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $theme.mode) {
                    Text("System").tag(ThemeMode.system)
                    Text("Light").tag(ThemeMode.light)
                    Text("Dark").tag(ThemeMode.dark)
                }
                .pickerStyle(.segmented)
            }
            Section("Light theme") {
                ThemeSwatchGrid(options: LightTheme.allCases.map { ($0.id, $0.displayName, $0.palette) }, selection: theme.light.id) {
                    theme.light = LightTheme(rawValue: $0) ?? .default
                }
            }
            Section("Dark theme") {
                ThemeSwatchGrid(options: DarkTheme.allCases.map { ($0.id, $0.displayName, $0.palette) }, selection: theme.dark.id) {
                    theme.dark = DarkTheme(rawValue: $0) ?? .default
                }
            }
        }
        .navigationTitle("Settings")
    }
}

private struct ThemeSwatchGrid: View {
    let options: [(id: String, name: String, palette: ThemePalette)]
    let selection: String
    let select: (String) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(options, id: \.id) { option in
                Button { select(option.id) } label: {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(option.palette.background)
                            .overlay(alignment: .bottomTrailing) {
                                Circle().fill(option.palette.accent).frame(width: 18, height: 18).padding(6)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(option.id == selection ? option.palette.accent : .secondary.opacity(0.3), lineWidth: option.id == selection ? 3 : 1))
                            .frame(height: 54)
                        Text(option.name).font(.caption).lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(option.id == selection ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
