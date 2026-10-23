import SwiftUI
import SubstratalCore

/// The on/off switch for one person's access to one app (ACX-01). Shows the resolved status first and the
/// paths one tap away. Platform-managed access can only be turned off and back on, never edited or revoked.
public struct AccessRow: View {
    let access: AccessSummary
    let onToggle: @MainActor (Bool) -> Void

    public init(_ access: AccessSummary, onToggle: @escaping @MainActor (Bool) -> Void) {
        self.access = access
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(spacing: 12) {
            AppIconPlaceholder(name: access.applicationName)
            VStack(alignment: .leading, spacing: 4) {
                Text(access.applicationName).font(.body.weight(.medium))
                HStack(spacing: 6) {
                    StatusBadge(access.status)
                    Text(access.sources.map(Self.sourceLabel).joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            Toggle("Access to \(access.applicationName)", isOn: Binding(
                get: { access.status == .active || access.status == .scheduled },
                set: { value in MainActor.assumeIsolated { onToggle(value) } }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    /// entitlement.source_labels in status-semantics.json.
    static func sourceLabel(_ source: String) -> String {
        switch source {
        case "purchase": "Purchased"
        case "trial": "Trial"
        case "admin_grant": "Granted by admin"
        case "org_seat": "Via organization"
        case "free": "Free app"
        case "subscription": "Standard plan"
        default: source.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

/// Initials tile used until icon upload exists (OPEN-QUESTIONS #1).
public struct AppIconPlaceholder: View {
    let name: String
    @Environment(\.palette) private var palette

    public init(name: String) { self.name = name }

    public var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.headline)
            .foregroundStyle(palette.accent)
            .frame(width: 36, height: 36)
            .background(palette.accentSubtle, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }
}
