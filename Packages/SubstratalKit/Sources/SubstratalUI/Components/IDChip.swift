import SwiftUI

/// A monospaced, copyable object ID (`usr_…`, `key_…`). Long-press copies it.
public struct IDChip: View {
    let id: String
    @State private var copied = false

    public init(_ id: String) { self.id = id }

    public var body: some View {
        Text(id)
            .font(.caption.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            .contextMenu {
                Button("Copy ID", systemImage: "doc.on.doc") { copy() }
            }
            .accessibilityLabel("ID \(id)")
            .accessibilityAction(named: "Copy ID") { copy() }
    }

    private func copy() {
        #if canImport(UIKit)
        UIPasteboard.general.string = id
        #endif
        copied = true
    }
}
