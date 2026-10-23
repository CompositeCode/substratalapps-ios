import SwiftUI
import SubstratalCore

/// GLB-03 system states driven by the API version monitor (CLIENT-ARCHITECTURE §4.1):
/// "Update available" (banner, once per day) when the server sends `Deprecation`, and
/// "Update required" (blocking) on `400 unsupported_api_version`.
public struct APIVersionBanner: View {
    let state: APIVersionState

    public init(_ state: APIVersionState) { self.state = state }

    public var body: some View {
        if case .deprecated(let sunset) = state {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "arrow.down.app")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Update available").font(.subheadline.weight(.semibold))
                    Text(sunsetText(sunset)).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
        }
    }

    private func sunsetText(_ date: Date?) -> String {
        guard let date else { return "This version of the app is being retired. Update when you can." }
        return "This version stops working on \(date.formatted(date: .long, time: .omitted)). Update before then."
    }
}

/// Full-screen blocker for `unsupported_api_version`. All API traffic stops until the app is updated.
public struct UpdateRequiredView: View {
    let supported: [String]
    let recheck: () -> Void

    public init(supported: [String], recheck: @escaping () -> Void) {
        self.supported = supported
        self.recheck = recheck
    }

    public var body: some View {
        ContentUnavailableView {
            Label("Update required", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
        } description: {
            Text("This version of Substratal can't talk to the service any more. Update the app from the App Store to continue.")
        } actions: {
            Button("Check again", action: recheck)
        }
    }
}
