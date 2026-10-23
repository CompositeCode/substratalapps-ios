import SwiftUI
import SubstratalCore

/// Stand-in for a screen whose UI isn't built yet. It shows the spec's ID, route, archetype and phase,
/// and links to the screen's spec and help page, so every route resolves from day one.
public struct ScreenPlaceholder: View {
    let screen: ScreenID
    let params: [String: String]
    @Environment(\.openURL) private var openURL

    public init(_ screen: ScreenID, params: [String: String] = [:]) {
        self.screen = screen
        self.params = params
    }

    public var body: some View {
        List {
            Section {
                LabeledContent("Screen", value: screen.rawValue)
                LabeledContent("Route", value: Route(screen, params).path).font(.body.monospaced())
                LabeledContent("Archetype", value: screen.info.archetype)
                LabeledContent("Phase", value: screen.info.phase)
            } footer: {
                Text("Not built yet. Its elements, data and API calls are specified in ios/SCREENS.md.")
            }
            if !params.isEmpty {
                Section("Parameters") {
                    ForEach(params.sorted(by: { $0.key < $1.key }), id: \.key) { LabeledContent($0.key, value: $0.value) }
                }
            }
            Section {
                Button("Open the screen spec", systemImage: "doc.text") {
                    openURL(URL(string: "https://compositecode.github.io/substratalapps-applications-specs/spec/00-shared/SCREEN-SPECS.html#\(screen.info.anchor)")!)
                }
                Button("Help for this screen", systemImage: "questionmark.circle") { openURL(HelpCenter.url(for: screen)) }
            }
        }
        .navigationTitle(screen.title)
    }
}

/// The "?" toolbar button every screen carries, opening its page in the shared help center.
public struct HelpButton: View {
    let screen: ScreenID
    @Environment(\.openURL) private var openURL

    public init(_ screen: ScreenID) { self.screen = screen }

    public var body: some View {
        Button("Help", systemImage: "questionmark.circle") { openURL(HelpCenter.url(for: screen)) }
            .help("Help for \(screen.title)")
    }
}
