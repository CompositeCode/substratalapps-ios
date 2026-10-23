// Generated from 00-shared/SCREEN-SPECS.md (spec targeting API v1.8.0) by scripts/generate-screen-ids.py. Do not edit by hand.
// The 12 C · Console screens (OPS-*, SEC-01, CFG-*, RPT-01, INT-01) are web-only; iOS skips them (PRODUCT-SPEC §2a, OPEN-QUESTIONS #27).
import Foundation

/// Every Hub screen, with the canonical ID, route and archetype from the shared spec.
public enum ScreenID: String, CaseIterable, Identifiable, Sendable, Codable {
    case auth01 = "AUTH-01"
    case auth02 = "AUTH-02"
    case auth03 = "AUTH-03"
    case auth04 = "AUTH-04"
    case auth05 = "AUTH-05"
    case auth06 = "AUTH-06"
    case auth07 = "AUTH-07"
    case acc01 = "ACC-01"
    case acc02 = "ACC-02"
    case acc03 = "ACC-03"
    case acc04 = "ACC-04"
    case acc05 = "ACC-05"
    case acc06 = "ACC-06"
    case acc07 = "ACC-07"
    case acc08 = "ACC-08"
    case app01 = "APP-01"
    case app02 = "APP-02"
    case app03 = "APP-03"
    case app04 = "APP-04"
    case app05 = "APP-05"
    case set01 = "SET-01"
    case set02 = "SET-02"
    case org01 = "ORG-01"
    case org02 = "ORG-02"
    case org03 = "ORG-03"
    case org04 = "ORG-04"
    case org05 = "ORG-05"
    case org06 = "ORG-06"
    case org07 = "ORG-07"
    case org08 = "ORG-08"
    case org09 = "ORG-09"
    case usr01 = "USR-01"
    case usr02 = "USR-02"
    case usr03 = "USR-03"
    case usr04 = "USR-04"
    case usr05 = "USR-05"
    case acx01 = "ACX-01"
    case acx02 = "ACX-02"
    case acx03 = "ACX-03"
    case acx04 = "ACX-04"
    case acx05 = "ACX-05"
    case rol01 = "ROL-01"
    case rol02 = "ROL-02"
    case rol03 = "ROL-03"
    case rol04 = "ROL-04"
    case apl01 = "APL-01"
    case apl02 = "APL-02"
    case apl03 = "APL-03"
    case apl04 = "APL-04"
    case apl05 = "APL-05"
    case apl06 = "APL-06"
    case key01 = "KEY-01"
    case key02 = "KEY-02"
    case key03 = "KEY-03"
    case key04 = "KEY-04"
    case whk01 = "WHK-01"
    case whk02 = "WHK-02"
    case whk03 = "WHK-03"
    case whk04 = "WHK-04"
    case bil01 = "BIL-01"
    case bil02 = "BIL-02"
    case bil03 = "BIL-03"
    case bil04 = "BIL-04"
    case aud01 = "AUD-01"
    case aud02 = "AUD-02"
    case ntf01 = "NTF-01"
    case ntf02 = "NTF-02"
    case ntf03 = "NTF-03"
    case ntf04 = "NTF-04"
    case ntf05 = "NTF-05"
    case ntf06 = "NTF-06"
    case apl07 = "APL-07"
    case glb01 = "GLB-01"
    case glb02 = "GLB-02"
    case glb03 = "GLB-03"

    public var id: String { rawValue }

    public struct Info: Sendable, Hashable {
        public let title: String
        public let domain: String
        public let route: String
        public let archetype: String
        public let phase: String
        /// The heading anchor in SCREEN-SPECS.md and in the help center.
        public let anchor: String
    }

    public var info: Info {
        switch self {
        case .auth01: Info(title: "Sign in", domain: "D1", route: "/sign-in", archetype: "auth", phase: "MVP", anchor: "auth-01--sign-in")
        case .auth02: Info(title: "Two-factor challenge", domain: "D1", route: "/sign-in/mfa", archetype: "auth", phase: "MVP", anchor: "auth-02--two-factor-challenge")
        case .auth03: Info(title: "Create account", domain: "D1", route: "/sign-up", archetype: "auth", phase: "MVP", anchor: "auth-03--create-account")
        case .auth04: Info(title: "Verify your email", domain: "D1", route: "/verify-email", archetype: "auth", phase: "MVP", anchor: "auth-04--verify-your-email")
        case .auth05: Info(title: "Forgot password", domain: "D1", route: "/forgot-password", archetype: "auth", phase: "MVP", anchor: "auth-05--forgot-password")
        case .auth06: Info(title: "Set a new password", domain: "D1", route: "/reset-password", archetype: "auth", phase: "MVP", anchor: "auth-06--set-a-new-password")
        case .auth07: Info(title: "Accept invitation", domain: "D1", route: "/invite", archetype: "auth", phase: "MVP", anchor: "auth-07--accept-invitation")
        case .acc01: Info(title: "Account & profile", domain: "D2", route: "/account", archetype: "settings", phase: "MVP", anchor: "acc-01--account--profile")
        case .acc02: Info(title: "Change email", domain: "D2", route: "/account/email", archetype: "form", phase: "MVP", anchor: "acc-02--change-email")
        case .acc03: Info(title: "Change password", domain: "D2", route: "/account/security/password", archetype: "form", phase: "MVP", anchor: "acc-03--change-password")
        case .acc04: Info(title: "Security", domain: "D2", route: "/account/security", archetype: "settings", phase: "MVP", anchor: "acc-04--security")
        case .acc05: Info(title: "Turn on two-factor", domain: "D2", route: "/account/security/2fa/enable", archetype: "wizard", phase: "MVP", anchor: "acc-05--turn-on-two-factor")
        case .acc06: Info(title: "Turn off two-factor", domain: "D2", route: "/account/security/2fa/disable", archetype: "confirm", phase: "MVP", anchor: "acc-06--turn-off-two-factor")
        case .acc07: Info(title: "Privacy", domain: "D2", route: "/account/privacy", archetype: "settings", phase: "MVP", anchor: "acc-07--privacy")
        case .acc08: Info(title: "Delete account", domain: "D2", route: "/account/privacy/delete", archetype: "confirm", phase: "MVP", anchor: "acc-08--delete-account")
        case .app01: Info(title: "Home — My Apps", domain: "D3", route: "/", archetype: "grid", phase: "MVP", anchor: "app-01--home--my-apps")
        case .app02: Info(title: "App info", domain: "D3", route: "/apps/:appId", archetype: "popover", phase: "MVP", anchor: "app-02--app-info")
        case .app03: Info(title: "Launch app", domain: "D3", route: "/apps/:appId/launch", archetype: "handoff", phase: "MVP", anchor: "app-03--launch-app")
        case .app04: Info(title: "App profile", domain: "D3", route: "/apps/:appId/profile", archetype: "form", phase: "Phase 2", anchor: "app-04--app-profile")
        case .app05: Info(title: "Past apps", domain: "D3", route: "/apps/past", archetype: "list", phase: "MVP", anchor: "app-05--past-apps")
        case .set01: Info(title: "Settings — Global", domain: "D4", route: "/settings", archetype: "settings", phase: "MVP", anchor: "set-01--settings--global")
        case .set02: Info(title: "Settings — Per app", domain: "D4", route: "/settings/apps/:appId", archetype: "settings", phase: "Phase 2", anchor: "set-02--settings--per-app")
        case .org01: Info(title: "Organizations", domain: "D5", route: "/orgs", archetype: "list", phase: "MVP", anchor: "org-01--organizations")
        case .org02: Info(title: "New organization", domain: "D5", route: "/orgs/new", archetype: "form", phase: "MVP", anchor: "org-02--new-organization")
        case .org03: Info(title: "Organization — Members", domain: "D5", route: "/orgs/:orgId/members", archetype: "detail", phase: "MVP", anchor: "org-03--organization--members")
        case .org04: Info(title: "Invite member", domain: "D5", route: "/orgs/:orgId/members/invite", archetype: "form", phase: "MVP", anchor: "org-04--invite-member")
        case .org05: Info(title: "Member actions", domain: "D5", route: "/orgs/:orgId/members/:userId", archetype: "confirm", phase: "MVP", anchor: "org-05--member-actions")
        case .org06: Info(title: "Organization — Apps & seats", domain: "D5", route: "/orgs/:orgId/apps", archetype: "tab", phase: "Phase 2", anchor: "org-06--organization--apps--seats")
        case .org07: Info(title: "Grant app to organization / member scope", domain: "D5", route: "/orgs/:orgId/apps/grant", archetype: "form", phase: "Phase 2", anchor: "org-07--grant-app-to-organization--member-scope")
        case .org08: Info(title: "Organization — Settings", domain: "D5", route: "/orgs/:orgId/settings", archetype: "settings", phase: "MVP", anchor: "org-08--organization--settings")
        case .org09: Info(title: "Invitation", domain: "D5", route: "/orgs/:orgId/invitation", archetype: "confirm", phase: "MVP", anchor: "org-09--invitation")
        case .usr01: Info(title: "Users", domain: "D6", route: "/admin/users", archetype: "table", phase: "MVP", anchor: "usr-01--users")
        case .usr02: Info(title: "Invite user", domain: "D6", route: "/admin/users/new", archetype: "form", phase: "MVP", anchor: "usr-02--invite-user")
        case .usr03: Info(title: "User — Overview", domain: "D6", route: "/admin/users/:userId", archetype: "detail", phase: "MVP", anchor: "usr-03--user--overview")
        case .usr04: Info(title: "User — Sessions", domain: "D6", route: "/admin/users/:userId/sessions", archetype: "tab", phase: "MVP", anchor: "usr-04--user--sessions")
        case .usr05: Info(title: "Suspend user", domain: "D6", route: "/admin/users/:userId/suspend", archetype: "confirm", phase: "MVP", anchor: "usr-05--suspend-user")
        case .acx01: Info(title: "User — Access", domain: "D7", route: "/admin/users/:userId/access", archetype: "tab", phase: "MVP", anchor: "acx-01--user--access")
        case .acx02: Info(title: "Grant access", domain: "D7", route: "/admin/users/:userId/access/grant", archetype: "form", phase: "MVP", anchor: "acx-02--grant-access")
        case .acx03: Info(title: "Turn off / edit access", domain: "D7", route: "/admin/entitlements/:entId", archetype: "confirm", phase: "MVP", anchor: "acx-03--turn-off--edit-access")
        case .acx04: Info(title: "Access check (Why?)", domain: "D7", route: "/admin/users/:userId/apps/:appId/why", archetype: "popover", phase: "MVP", anchor: "acx-04--access-check-why")
        case .acx05: Info(title: "Access (all)", domain: "D7", route: "/admin/access", archetype: "table", phase: "MVP", anchor: "acx-05--access-all")
        case .rol01: Info(title: "Roles", domain: "D8", route: "/admin/roles", archetype: "list", phase: "MVP", anchor: "rol-01--roles")
        case .rol02: Info(title: "Role detail", domain: "D8", route: "/admin/roles/:roleId", archetype: "detail", phase: "MVP", anchor: "rol-02--role-detail")
        case .rol03: Info(title: "New role", domain: "D8", route: "/admin/roles/new", archetype: "form", phase: "MVP", anchor: "rol-03--new-role")
        case .rol04: Info(title: "User — Roles", domain: "D8", route: "/admin/users/:userId/roles", archetype: "tab", phase: "MVP", anchor: "rol-04--user--roles")
        case .apl01: Info(title: "Applications", domain: "D9", route: "/dev/apps", archetype: "list", phase: "MVP", anchor: "apl-01--applications")
        case .apl02: Info(title: "Register application", domain: "D9", route: "/dev/apps/new", archetype: "wizard", phase: "MVP", anchor: "apl-02--register-application")
        case .apl03: Info(title: "Application — Overview", domain: "D9", route: "/dev/apps/:appId", archetype: "detail", phase: "MVP", anchor: "apl-03--application--overview")
        case .apl04: Info(title: "Settings schema", domain: "D9", route: "/dev/apps/:appId/schema", archetype: "tab", phase: "Phase 2", anchor: "apl-04--settings-schema")
        case .apl05: Info(title: "Permissions & roles", domain: "D9", route: "/dev/apps/:appId/roles", archetype: "tab", phase: "Phase 2", anchor: "apl-05--permissions--roles")
        case .apl06: Info(title: "Review", domain: "D9", route: "/dev/apps/:appId/review", archetype: "form", phase: "Phase 3", anchor: "apl-06--review")
        case .key01: Info(title: "API keys", domain: "D10", route: "/dev/keys", archetype: "table", phase: "MVP", anchor: "key-01--api-keys")
        case .key02: Info(title: "Create API key", domain: "D10", route: "/dev/keys/new", archetype: "form", phase: "MVP", anchor: "key-02--create-api-key")
        case .key03: Info(title: "Secret reveal", domain: "D10", route: "(modal)", archetype: "secret", phase: "MVP", anchor: "key-03--secret-reveal")
        case .key04: Info(title: "API key detail", domain: "D10", route: "/dev/keys/:keyId", archetype: "detail", phase: "MVP", anchor: "key-04--api-key-detail")
        case .whk01: Info(title: "Webhooks", domain: "D10", route: "/dev/webhooks", archetype: "list", phase: "Phase 2", anchor: "whk-01--webhooks")
        case .whk02: Info(title: "Add / edit webhook", domain: "D10", route: "/dev/webhooks/new", archetype: "form", phase: "Phase 2", anchor: "whk-02--add--edit-webhook")
        case .whk03: Info(title: "Webhook — Deliveries", domain: "D10", route: "/dev/webhooks/:hookId", archetype: "detail", phase: "Phase 2", anchor: "whk-03--webhook--deliveries")
        case .whk04: Info(title: "Delivery detail", domain: "D10", route: "/dev/webhooks/:hookId/deliveries/:deliveryId", archetype: "popover", phase: "Phase 2", anchor: "whk-04--delivery-detail")
        case .bil01: Info(title: "My plan", domain: "D11", route: "/billing", archetype: "settings", phase: "Phase 2", anchor: "bil-01--my-plan")
        case .bil02: Info(title: "Organization subscription", domain: "D11", route: "/orgs/:orgId/subscription", archetype: "tab", phase: "Phase 2", anchor: "bil-02--organization-subscription")
        case .bil03: Info(title: "Checkout / billing portal", domain: "D11", route: "/billing/return", archetype: "handoff", phase: "Phase 2", anchor: "bil-03--checkout--billing-portal")
        case .bil04: Info(title: "Tenant & infrastructure", domain: "D11", route: "/dev/tenant", archetype: "detail", phase: "Phase 2", anchor: "bil-04--tenant--infrastructure")
        case .aud01: Info(title: "Audit log", domain: "D12", route: "/admin/audit", archetype: "table", phase: "MVP", anchor: "aud-01--audit-log")
        case .aud02: Info(title: "Audit event", domain: "D12", route: "/admin/audit/:eventId", archetype: "popover", phase: "MVP", anchor: "aud-02--audit-event")
        case .ntf01: Info(title: "Inbox", domain: "D13", route: "/inbox", archetype: "list", phase: "Phase 2", anchor: "ntf-01--inbox")
        case .ntf02: Info(title: "Notification", domain: "D13", route: "/inbox/:notificationId", archetype: "popover", phase: "Phase 2", anchor: "ntf-02--notification")
        case .ntf03: Info(title: "Devices & notifications", domain: "D13", route: "/account/devices", archetype: "settings", phase: "Phase 2", anchor: "ntf-03--devices--notifications")
        case .ntf04: Info(title: "Turn on notifications", domain: "D13", route: "/account/devices/enable", archetype: "wizard", phase: "Phase 2", anchor: "ntf-04--turn-on-notifications")
        case .ntf05: Info(title: "User — Notifications & devices", domain: "D13", route: "/admin/users/:userId/notifications", archetype: "tab", phase: "Phase 2", anchor: "ntf-05--user--notifications--devices")
        case .ntf06: Info(title: "Send notification", domain: "D13", route: "/admin/notifications/new", archetype: "form", phase: "Phase 2", anchor: "ntf-06--send-notification")
        case .apl07: Info(title: "Push credentials", domain: "D9", route: "/dev/apps/:appId/push", archetype: "tab", phase: "Phase 2", anchor: "apl-07--push-credentials")
        case .glb01: Info(title: "Command palette", domain: "G", route: "(overlay)", archetype: "overlay", phase: "MVP", anchor: "glb-01--command-palette")
        case .glb02: Info(title: "Manage hub", domain: "G", route: "/manage", archetype: "hub", phase: "MVP", anchor: "glb-02--manage-hub")
        case .glb03: Info(title: "System states", domain: "G", route: "(global)", archetype: "overlay", phase: "MVP", anchor: "glb-03--system-states")
        }
    }

    public var title: String { info.title }
}
