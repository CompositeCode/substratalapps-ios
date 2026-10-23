import SwiftUI
import SubstratalUI

/// NTF-01 Inbox. Push and inbox are built in the API (v1.8.0); this screen lands with Phase 2.
struct InboxView: View {
    var body: some View {
        ContentUnavailableView("You're all caught up",
                               systemImage: "tray",
                               description: Text("Security alerts and notifications from your apps appear here."))
            .navigationTitle("Inbox")
    }
}
