#if os(iOS)
import SwiftUI

/// KEY-03 and every other one-time secret (webhook signing secrets, SCIM tokens).
/// It can't be dismissed until the person confirms they saved it. The secret is hidden while the
/// screen is captured, and the copy expires from the pasteboard after 60 s and never syncs via Universal Clipboard.
public struct SecretRevealSheet: View {
    let title: String
    let secret: String
    let note: String
    let onDone: () -> Void

    @State private var acknowledged = false
    @State private var copied = false
    @State private var isCaptured = false

    public init(title: String, secret: String, note: String, onDone: @escaping () -> Void) {
        self.title = title
        self.secret = secret
        self.note = note
        self.onDone = onDone
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("You won't be able to see this again", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline.weight(.semibold))
                    Text(note).font(.footnote).foregroundStyle(.secondary)
                }
                Section("Secret") {
                    Group {
                        if isCaptured {
                            Label("Hidden while the screen is being recorded or mirrored", systemImage: "eye.slash")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(secret).font(.body.monospaced()).textSelection(.enabled)
                        }
                    }
                    .privacySensitive()
                    Button(copied ? "Copied — clears in 60 seconds" : "Copy secret", systemImage: copied ? "checkmark" : "doc.on.doc") {
                        copySecret()
                    }
                    .disabled(isCaptured)
                }
                Section {
                    Toggle("I've stored this secret somewhere safe", isOn: $acknowledged)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone).disabled(!acknowledged)
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear(perform: updateCaptureState)
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in updateCaptureState() }
    }

    private func copySecret() {
        UIPasteboard.general.setItems([[UIPasteboard.typeAutomatic: secret]],
                                      options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)])
        copied = true
    }

    private func updateCaptureState() {
        isCaptured = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.isCaptured ?? false
    }
}

#Preview {
    Text("Behind").sheet(isPresented: .constant(true)) {
        SecretRevealSheet(title: "timetrack-backend", secret: "satk_live_9f2a1c7e4b3d8f0a2c5e7b1d9f3a6c8e",
                          note: "Use it as a Bearer token from your server. API keys never belong in an app or a browser.") {}
    }
}
#endif
