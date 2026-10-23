import SwiftUI
import SubstratalCore

/// The navigation tree from INFORMATION-ARCHITECTURE §1: the same sections, order and icons on every platform.
enum HubSection: String, CaseIterable, Identifiable, Hashable, Codable {
    // Personal
    case home, inbox, organizations, account, billing, settings
    // Administration
    case users, access, roles, audit, sendNotification
    // Developer
    case applications, apiKeys, webhooks, tenant
    // Compact-only hub (GLB-02) that holds Administration + Developer
    case manage

    var id: String { rawValue }

    enum Group: String { case personal = "Personal", administration = "Administration", developer = "Developer" }

    var group: Group {
        switch self {
        case .home, .inbox, .organizations, .account, .billing, .settings, .manage: .personal
        case .users, .access, .roles, .audit, .sendNotification: .administration
        case .applications, .apiKeys, .webhooks, .tenant: .developer
        }
    }

    var title: String {
        switch self {
        case .home: "Home"
        case .inbox: "Inbox"
        case .organizations: "Organizations"
        case .account: "Account"
        case .billing: "Plan & Billing"
        case .settings: "Settings"
        case .users: "Users"
        case .access: "Access"
        case .roles: "Roles"
        case .audit: "Audit Log"
        case .sendNotification: "Send notification"
        case .applications: "Applications"
        case .apiKeys: "API Keys"
        case .webhooks: "Webhooks"
        case .tenant: "Tenant"
        case .manage: "Manage"
        }
    }

    /// The iPhone tab bar's shorter label (PLATFORM-SPEC §2: Home · Inbox · Orgs · Manage · Account).
    var compactTitle: String { self == .organizations ? "Orgs" : title }

    /// SF Symbols from INFORMATION-ARCHITECTURE §5.
    var symbol: String {
        switch self {
        case .home: "square.grid.2x2"
        case .inbox: "tray"
        case .organizations: "person.3"
        case .account: "person.crop.circle"
        case .billing: "creditcard"
        case .settings: "gearshape"
        case .users: "person.2"
        case .access: "switch.2"
        case .roles: "checkmark.shield"
        case .audit: "list.bullet.clipboard"
        case .sendNotification: "bell.badge"
        case .applications: "shippingbox"
        case .apiKeys: "key"
        case .webhooks: "arrow.triangle.branch"
        case .tenant: "server.rack"
        case .manage: "slider.horizontal.3"
        }
    }

    /// The screen at the root of this section's stack.
    var root: ScreenID {
        switch self {
        case .home: .app01
        case .inbox: .ntf01
        case .organizations: .org01
        case .account: .acc01
        case .billing: .bil01
        case .settings: .set01
        case .users: .usr01
        case .access: .acx05
        case .roles: .rol01
        case .audit: .aud01
        case .sendNotification: .ntf06
        case .applications: .apl01
        case .apiKeys: .key01
        case .webhooks: .whk01
        case .tenant: .bil04
        case .manage: .glb02
        }
    }

    /// INFORMATION-ARCHITECTURE §2 visibility rules.
    func isVisible(for caps: Capabilities) -> Bool {
        switch self {
        case .home, .inbox, .organizations, .account, .billing, .settings: true
        case .manage: caps.showsManage
        case .users: caps.canListUsers
        case .access: caps.canManageEntitlements || caps.ownsApps
        case .roles: caps.canListUsers || caps.canManageRoles
        case .audit: caps.canViewAudit
        case .sendNotification: caps.canSendNotifications
        case .applications: caps.showsDeveloper
        case .apiKeys: caps.canManageAPIKeys || caps.ownsApps
        case .webhooks: caps.canManageWebhooks || caps.ownsApps
        case .tenant: caps.canManageTenants || !caps.ownedTenantIDs.isEmpty
        }
    }

    static let administration: [HubSection] = [.users, .access, .roles, .audit, .sendNotification]
    static let developer: [HubSection] = [.applications, .apiKeys, .webhooks, .tenant]
    /// iPhone: Home · Inbox · Orgs · Manage · Account (Plan & Billing and Settings live inside Account).
    static let compactTabs: [HubSection] = [.home, .inbox, .organizations, .manage, .account]
    /// iPad sidebar, Personal group.
    static let personal: [HubSection] = [.home, .inbox, .organizations, .account, .billing, .settings]

    /// Which section a deep-linked screen belongs to, for picking the tab to push it onto.
    static func owning(_ screen: ScreenID, compact: Bool) -> HubSection {
        let route = screen.info.route
        let section: HubSection = switch true {
        case route == "/manage": .manage
        case route.hasPrefix("/inbox"): .inbox
        case route.hasPrefix("/orgs"): .organizations
        case route.hasPrefix("/billing"): .billing
        case route.hasPrefix("/settings"): .settings
        case route.hasPrefix("/account"): .account
        case route.hasPrefix("/admin/users"), route.hasPrefix("/admin/entitlements"): .users
        case route.hasPrefix("/admin/access"): .access
        case route.hasPrefix("/admin/roles"): .roles
        case route.hasPrefix("/admin/audit"): .audit
        case route.hasPrefix("/admin/notifications"): .sendNotification
        case route.hasPrefix("/dev/apps"): .applications
        case route.hasPrefix("/dev/keys"): .apiKeys
        case route.hasPrefix("/dev/webhooks"): .webhooks
        case route.hasPrefix("/dev/tenant"): .tenant
        default: .home
        }
        guard compact else { return section }
        switch section {
        case .billing, .settings: return .account
        case _ where section.group != .personal: return .manage
        default: return section
        }
    }
}
