import SwiftUI
import SubstratalCore

/// Icon + label, never colour alone (ACCESSIBILITY, status-semantics.json).
public struct StatusBadge: View {
    let status: StatusKind
    var label: String?

    public init(_ status: StatusKind, label: String? = nil) {
        self.status = status
        self.label = label
    }

    public var body: some View {
        Label(label ?? status.label, systemImage: status.sfSymbol)
            .font(.caption.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(status.role.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.role.color.opacity(0.14), in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Status: \(label ?? status.label)")
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach([StatusKind.active, .scheduled, .disabled, .expired, .revoked, .none, .invited, .suspended, .pending], id: \.self) {
            StatusBadge($0)
        }
    }.padding()
}
