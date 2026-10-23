import SwiftUI
import SubstratalCore
import SubstratalUI

/// AUD-01 Audit log, newest first, grouped by day. AUD-02 opens as a sheet (popover archetype).
struct AuditLogView: View {
    @Environment(SessionModel.self) private var session
    @State private var state: LoadState<[AuditEntry]> = .idle
    @State private var selected: AuditEntry?

    var body: some View {
        LoadStateView(state, retry: { Task { await load() } }) { events in
            List {
                ForEach(groupedByDay(events), id: \.0) { day, items in
                    Section(day.formatted(date: .complete, time: .omitted)) {
                        ForEach(items) { event in
                            Button { selected = event } label: { AuditRow(event: event) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .refreshable { await load() }
        }
        .navigationTitle("Audit Log")
        .sheet(item: $selected) { event in AuditEventSheet(event: event).presentationDetents([.medium, .large]) }
        .task { await load() }
    }

    private func groupedByDay(_ events: [AuditEntry]) -> [(Date, [AuditEntry])] {
        Dictionary(grouping: events) { Calendar.current.startOfDay(for: $0.timestamp) }
            .sorted { $0.key > $1.key }
    }

    private func load() async {
        do { state = .loaded(try await session.service.auditEvents(cursor: nil).items) }
        catch let error as APIError { state = .failed(error) } catch {}
    }
}

private struct AuditRow: View {
    let event: AuditEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(event.action).font(.body.monospaced().weight(.medium))
                Spacer()
                Text(event.timestamp, style: .time).font(.caption).foregroundStyle(.secondary)
            }
            Text("\(event.actorType == "api_key" ? "API key" : event.actorType.capitalized) \(event.actorID)")
                .font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
        }
        .contentShape(Rectangle())
    }
}

/// AUD-02 Audit event.
struct AuditEventSheet: View {
    let event: AuditEntry

    var body: some View {
        NavigationStack {
            List {
                LabeledContent("Action", value: event.action)
                LabeledContent("When") { Text(event.timestamp.formatted(date: .abbreviated, time: .standard)) }
                LabeledContent("Actor", value: event.actorID)
                if let target = event.targetID { LabeledContent("Target", value: "\(event.targetType ?? "") \(target)") }
                if let app = event.applicationID { LabeledContent("Application", value: app) }
                if let request = event.requestID { LabeledContent("Request ID", value: request) }
                IDChip(event.id)
            }
            .font(.callout)
            .navigationTitle("Audit event")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
