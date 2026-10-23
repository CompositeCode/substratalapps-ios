import Foundation

/// Status semantics shared by every Hub app (00-shared/status-semantics.json).
/// Every badge is icon + label; colour comes from `role`, never alone.
public enum StatusKind: Hashable, Sendable {
    case active, scheduled, disabled, expired, revoked, none, invited, suspended, deleted, pending, important, unread
    /// An enum value this build doesn't know. Enums grow without a version bump (NFR → Versioning).
    case unknown(String)

    public enum Role: String, Sendable { case success, info, warning, critical, neutral, accent }

    public init(rawValue: String) {
        switch rawValue {
        case "active": self = .active
        case "scheduled": self = .scheduled
        case "disabled": self = .disabled
        case "expired": self = .expired
        case "revoked": self = .revoked
        case "none": self = .none
        case "invited": self = .invited
        case "suspended": self = .suspended
        case "deleted": self = .deleted
        case "pending": self = .pending
        case "important": self = .important
        case "unread": self = .unread
        default: self = .unknown(rawValue)
        }
    }

    public var label: String {
        switch self {
        case .active: "Active"
        case .scheduled: "Scheduled"
        case .disabled: "Turned off"
        case .expired: "Expired"
        case .revoked: "Revoked"
        case .none: "No access"
        case .invited: "Invited"
        case .suspended: "Suspended"
        case .deleted: "Deleted"
        case .pending: "Pending"
        case .important: "Important"
        case .unread: "Unread"
        case .unknown(let raw): raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    public var role: Role {
        switch self {
        case .active: .success
        case .scheduled, .pending: .info
        case .disabled, .suspended: .warning
        case .revoked, .deleted, .important: .critical
        case .expired, .none, .unknown: .neutral
        case .invited, .unread: .accent
        }
    }

    public var sfSymbol: String {
        switch self {
        case .active: "checkmark.circle.fill"
        case .scheduled: "calendar"
        case .disabled, .suspended: "pause.circle.fill"
        case .expired: "clock"
        case .revoked: "xmark.circle.fill"
        case .none: "minus.circle"
        case .invited: "envelope"
        case .deleted: "trash"
        case .pending: "hourglass"
        case .important: "exclamationmark.circle"
        case .unread: "circle.fill"
        case .unknown: "questionmark.circle"
        }
    }

    // MARK: Mappings from API enums (status-semantics.json → mappings)

    public static func applicationReview(_ raw: String) -> StatusKind {
        switch raw {
        case "approved": .active
        case "pending_review": .pending
        case "rejected": .revoked
        case "suspended": .suspended
        default: .unknown(raw)
        }
    }

    public static func webhook(_ raw: String) -> StatusKind {
        switch raw {
        case "healthy": .active
        case "unhealthy": .disabled
        case "disabled": .expired
        default: .unknown(raw)
        }
    }
}
