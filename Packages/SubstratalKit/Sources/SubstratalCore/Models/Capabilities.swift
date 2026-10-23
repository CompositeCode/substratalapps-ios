import Foundation

/// What the signed-in person may see and do (CLIENT-ARCHITECTURE §5, INFORMATION-ARCHITECTURE §2).
/// Navigation and every action read only from this; the server is always the authority.
public struct Capabilities: Sendable, Hashable {
    public var platformPermissions: Set<String>
    public var ownedApplicationIDs: [String]
    public var ownedTenantIDs: [String]
    public var adminOfOrganizationIDs: [String]
    public var plan: String

    public init(platformPermissions: Set<String> = [], ownedApplicationIDs: [String] = [], ownedTenantIDs: [String] = [],
                adminOfOrganizationIDs: [String] = [], plan: String = "free") {
        self.platformPermissions = platformPermissions
        self.ownedApplicationIDs = ownedApplicationIDs
        self.ownedTenantIDs = ownedTenantIDs
        self.adminOfOrganizationIDs = adminOfOrganizationIDs
        self.plan = plan
    }

    public static let none = Capabilities()

    public var canListUsers: Bool { platformPermissions.contains("users.list") }
    public var canManageUsers: Bool { platformPermissions.contains("users.manage") }
    public var canManageEntitlements: Bool { platformPermissions.contains("entitlements.manage") }
    public var canManageRoles: Bool { platformPermissions.contains("roles.manage") }
    public var canViewAudit: Bool { platformPermissions.contains("audit.view") }
    public var canManageApplications: Bool { platformPermissions.contains("applications.manage") }
    public var canManageAPIKeys: Bool { platformPermissions.contains("api_keys.manage") }
    public var canManageWebhooks: Bool { platformPermissions.contains("webhooks.manage") }
    public var canManageTenants: Bool { platformPermissions.contains("tenants.manage") }
    public var canManageBilling: Bool { platformPermissions.contains("billing.manage") }
    public var canSendNotifications: Bool { platformPermissions.contains("notifications.send") }
    public var ownsApps: Bool { !ownedApplicationIDs.isEmpty }

    // MARK: Section visibility (INFORMATION-ARCHITECTURE §2)

    public var showsAdministration: Bool {
        canListUsers || canManageEntitlements || canManageRoles || canViewAudit || canSendNotifications || ownsApps
    }
    public var showsDeveloper: Bool {
        ownsApps || !ownedTenantIDs.isEmpty || canManageApplications || canManageAPIKeys || canManageWebhooks || canManageTenants
    }
    /// The Manage tab is removed (not disabled) for people with no rights in either section.
    public var showsManage: Bool { showsAdministration || showsDeveloper }

    public func shows(_ screen: ScreenID) -> Bool {
        switch screen {
        case .usr01, .usr02, .usr03, .usr04, .usr05: canListUsers
        case .acx05: canManageEntitlements || ownsApps
        case .rol01, .rol02, .rol04: canListUsers
        case .rol03: canManageRoles
        case .aud01, .aud02: canViewAudit
        case .ntf06: canSendNotifications
        case .apl01, .apl02, .apl03: showsDeveloper
        case .key01, .key02, .key03, .key04: canManageAPIKeys || ownsApps
        case .whk01, .whk02, .whk03, .whk04: canManageWebhooks || ownsApps
        case .bil04: canManageTenants || !ownedTenantIDs.isEmpty
        default: true
        }
    }

    /// Superadmin's full grant, used by demo mode and previews.
    public static let superadmin = Capabilities(
        platformPermissions: ["users.list", "users.manage", "entitlements.manage", "applications.manage", "roles.manage",
                              "organizations.manage", "billing.manage", "billing.refund", "audit.view", "webhooks.manage",
                              "api_keys.manage", "notifications.send", "tenants.manage"],
        ownedApplicationIDs: ["app_hub"], ownedTenantIDs: ["tnt_system"], plan: "standard")
}
