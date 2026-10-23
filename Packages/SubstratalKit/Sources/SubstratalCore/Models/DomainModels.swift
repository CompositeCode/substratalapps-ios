import Foundation

/// A page from a cursor-paginated list (Conventions → Pagination).
public struct Page<Item: Sendable>: Sendable {
    public var items: [Item]
    public var nextCursor: String?
    public init(items: [Item], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public struct UserSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var email: String
    public var status: StatusKind
    public var mfaEnabled: Bool
    public var emailVerified: Bool
    public var testMode: Bool
    public var plan: String?
    public var createdAt: Date?
    public var lastLoginAt: Date?
    public var expiresAt: Date?

    public init(id: String, email: String, status: StatusKind, mfaEnabled: Bool = false, emailVerified: Bool = true,
                testMode: Bool = false, plan: String? = "free", createdAt: Date? = nil, lastLoginAt: Date? = nil, expiresAt: Date? = nil) {
        self.id = id; self.email = email; self.status = status; self.mfaEnabled = mfaEnabled; self.emailVerified = emailVerified
        self.testMode = testMode; self.plan = plan; self.createdAt = createdAt; self.lastLoginAt = lastLoginAt; self.expiresAt = expiresAt
    }

    /// Initials for the avatar placeholder (avatar upload is OPEN-QUESTIONS #1).
    public var initials: String {
        let name = email.split(separator: "@").first ?? ""
        let parts = name.split(whereSeparator: { $0 == "." || $0 == "_" || $0 == "-" || $0 == "+" })
        let letters = parts.prefix(2).compactMap(\.first).map(String.init).joined()
        return (letters.isEmpty ? String(name.prefix(1)) : letters).uppercased()
    }
}

public struct ApplicationSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var slug: String
    public var name: String
    public var summary: String?
    public var visibility: String
    public var accessTier: String
    public var reviewStatus: StatusKind

    public init(id: String, slug: String, name: String, summary: String?, visibility: String, accessTier: String, reviewStatus: StatusKind) {
        self.id = id; self.slug = slug; self.name = name; self.summary = summary
        self.visibility = visibility; self.accessTier = accessTier; self.reviewStatus = reviewStatus
    }
}

public struct APIKeySummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    /// `platform` or an `application_id`.
    public var scope: String
    public var mode: String
    public var intendedUse: String
    public var restrictDestructive: Bool
    public var permissions: [String]
    public var secretHint: String?
    public var lastUsedAt: Date?
    public var expiresAt: Date?
    public var revokedAt: Date?
    public var createdAt: Date?

    public init(id: String, name: String, scope: String, mode: String, intendedUse: String, restrictDestructive: Bool,
                permissions: [String], secretHint: String?, lastUsedAt: Date? = nil, expiresAt: Date? = nil,
                revokedAt: Date? = nil, createdAt: Date? = nil) {
        self.id = id; self.name = name; self.scope = scope; self.mode = mode; self.intendedUse = intendedUse
        self.restrictDestructive = restrictDestructive; self.permissions = permissions; self.secretHint = secretHint
        self.lastUsedAt = lastUsedAt; self.expiresAt = expiresAt; self.revokedAt = revokedAt; self.createdAt = createdAt
    }

    public var status: StatusKind {
        if revokedAt != nil { return .revoked }
        if let expiresAt, expiresAt < .now { return .expired }
        return .active
    }
}

/// A newly created key. `secret` exists only in memory, only until KEY-03 is acknowledged.
public struct CreatedAPIKey: Sendable, Hashable {
    public var key: APIKeySummary
    public var secret: String
    public init(key: APIKeySummary, secret: String) { self.key = key; self.secret = secret }
}

public struct NewAPIKey: Sendable, Hashable {
    public var name = ""
    public var scope = "platform"
    public var permissions: Set<String> = []
    public var mode = "live"
    public var intendedUse = "service"
    public var expiresAt: Date? = Calendar.current.date(byAdding: .year, value: 1, to: .now)
    public init() {}
}

public struct AuditEntry: Identifiable, Hashable, Sendable {
    public var id: String
    public var action: String
    public var actorType: String
    public var actorID: String
    public var targetType: String?
    public var targetID: String?
    public var applicationID: String?
    public var requestID: String?
    public var timestamp: Date

    public init(id: String, action: String, actorType: String, actorID: String, targetType: String?, targetID: String?,
                applicationID: String?, requestID: String?, timestamp: Date) {
        self.id = id; self.action = action; self.actorType = actorType; self.actorID = actorID; self.targetType = targetType
        self.targetID = targetID; self.applicationID = applicationID; self.requestID = requestID; self.timestamp = timestamp
    }
}

public struct RoleSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var scope: String
    public var description: String?
    public var permissions: [String]
    public var seed: Bool
    public var assignmentCount: Int

    public init(id: String, name: String, scope: String, description: String?, permissions: [String], seed: Bool, assignmentCount: Int) {
        self.id = id; self.name = name; self.scope = scope; self.description = description
        self.permissions = permissions; self.seed = seed; self.assignmentCount = assignmentCount
    }
}

/// One resolved row of a user's access to an Application (ACX-01): the status first, the paths one tap away.
public struct AccessSummary: Identifiable, Hashable, Sendable {
    public var id: String { applicationID }
    public var applicationID: String
    public var applicationName: String
    public var status: StatusKind
    public var sources: [String]
    public var platformManaged: Bool

    public init(applicationID: String, applicationName: String, status: StatusKind, sources: [String], platformManaged: Bool) {
        self.applicationID = applicationID; self.applicationName = applicationName; self.status = status
        self.sources = sources; self.platformManaged = platformManaged
    }
}

public struct UserQuery: Sendable, Hashable {
    public var text = ""
    public var status: String?
    public var roleIDs: [String] = []
    public init() {}
}
