# Substratal Apps — iOS Management App Plan

Plan for the first client of the Substratal Apps Platform API: a native iOS/iPadOS app administrators use to manage and monitor `https://api.substratalapps.com`.

Sources reviewed on 2026-10-21:

- API spec site and repo: [compositecode.github.io/substratalapps.com](https://compositecode.github.io/substratalapps.com/), `CompositeCode/substratalapps.com` at `967e114` (2026-10-20). Covers `openapi.yaml` 3.1, 118 operations, the Go implementation, Terraform, `plan-remaining.md` and `remaining_manual_steps.md`.
- Client specs: [compositecode.github.io/substratalapps-applications-specs](https://compositecode.github.io/substratalapps-applications-specs/), `CompositeCode/substratalapps-applications-specs` at `e296d7e` (2026-10-18). Covers the shared spec, the iOS handoff, the 75-screen inventory and the themes.
- Live probes (2026-10-21, when paths still carried `/v1`): `GET /health` returned `200`, `GET /applications` without a token returned `401` with the documented error envelope, and `/.well-known/jwks.json` serves an RS256 key. `dashboard.substratalapps.com` and `auth.substratalapps.com` don't resolve in DNS.

The companion document [api-gaps.md](api-gaps.md) lists what the API is missing.

> **Update, 2026-10-23.** Superseded where this conflicts:
>
> - **API versioning moved from the URL to a header.** Every path is at the host root (`https://api.substratalapps.com/users`, not `/v1/users`), and every request sends `Substratal-Version: 1`. `/v1/…` returns `404`. Missing the header returns `400 api_version_required`. `Deprecation`/`Sunset` response headers announce retirement, and `400 unsupported_api_version` follows it. The app implements this in `APIVersionMiddleware` and the GLB-03 Update available / Update required states. See the [help center's versioning page](https://compositecode.github.io/substratalapps-applications-specs/help/developers/api-versioning.html).
> - **The API is now `1.0.0-draft.9`, with 124 operations.** Since this plan was written it gained test-mode user expiry, self-service app registration, audit exports, SCIM, `GET /users?role_id=` and `POST /users/{id}/sessions/revoke-all`.
> - **API gaps are tracked as `[api-gaps]` issues in the API repo** (#38–#65). See [api-gaps.md](api-gaps.md) for the mapping.
> - **The Operations section (§4–§5.1–5.3, §5.9) is web-only for now.** The specs adopted the console screens (OPS-*, SEC-01, CFG-*, RPT-01, INT-01) for the web Hub only, behind its same-origin Ops gateway. iOS skips them (PRODUCT-SPEC §2a, OPEN-QUESTIONS #27), and this app follows that.
> - **Help and documentation live in the shared help center** at <https://compositecode.github.io/substratalapps-applications-specs/help/>. Every screen's **?** button opens its page there.

---

## 1. Verdict: is the API ready to build against?

**Yes for most of the management surface. No for three things the request explicitly asks for.**

| Area in the request | API today | Ready? |
|---|---|---|
| User authentication: users, roles, permissions | Users CRUD, suspend, sessions, MFA reset, platform and app Roles, `effective-permissions`, Organizations | ✅ Build now |
| API key management | Full CRUD plus rotate, test/live mode, agent keys with `restrict_destructive`, app-confined scopes | ✅ Build now |
| Application management (list, add, configure, review, suspend) | `GET/POST/PATCH /applications`, review lifecycle, push credentials, app keys, webhooks | ⚠️ Partly. Adding, configuring and suspending work. **Removing an application has no endpoint** (no `DELETE`, no `archived` status). |
| Audit logs and user activity | `GET /audit-events` with rich filters, one-year hot window | ✅ for state changes. ⚠️ Sign-ins, failed logins, lockouts and `401`/`403`s go to CloudWatch only. No API reads them. |
| Monitoring dashboards: usage and performance | Nothing. Metrics exist only in CloudWatch (API Gateway, Lambda, Aurora). | ❌ Needs new endpoints |
| Alerts and notifications for critical events | CloudWatch alarms go to SNS and then **email only**. Platform push alerts exist, but only for `security.*`, `account.*` and `billing.*` user alerts. | ❌ Needs an ops-alert path |
| Configuration settings for the API system | Rate limits are hard-coded in `internal/core/ratelimit.go`. No feature flags and no system config resource. | ❌ Needs a config resource |
| Integrations with external tools | Webhooks (domain events), the MCP server, Stripe | ✅ for domain events. Ops integrations go through SNS (see §9). |

Operational blockers that are not code:

1. **Email links point at a domain that doesn't exist.** Inviting a user (USR-02) or sending a password reset sends a link to `dashboard.substratalapps.com`, which doesn't resolve. The same domain must host the `apple-app-site-association` file for Universal Links. It is the cheapest item on the list and it blocks the invite flow (see api-gaps G-01).
2. **`app_hub` must be registered** as an Application, with an APNs credential, before the app can receive push (client spec, CLIENT-ARCHITECTURE §2).
3. **The protected superadmin's password** has to be set with `cmd/admin bootstrap` or a reset (`remaining_manual_steps.md`). That account then needs TOTP enrolled before it is used on a phone.

---

## 2. Scope decision: one app, admin first

The client spec already defines this app. **Substratal Hub for iOS** is one universal SwiftUI app that serves every persona and gates by Capabilities. Administrators get a **Manage** tab that end users never see. The request describes a management app, and the Manage tab plus Developer section is that app.

**Recommendation:** build the Hub's iOS codebase, but in admin-first order: the Manage tab, its screens, and a new **Operations** section for monitoring, alerts and config, which the spec doesn't cover. End-user screens (Home, Inbox, Orgs, Plan & Billing) come after, in the same codebase. This avoids a second admin-only app that would duplicate the session, API client, theming and push work. It also matches the spec's Definition of Done and the macOS sharing plan (`SubstratalKit`).

The alternative is a separate admin-only app, "Substratal Console". It fits only if you want a different bundle ID, a private distribution channel (Apple Business Manager custom app or TestFlight only), or an MDM-managed admin device. It doubles the APNs credentials, since an Application has one APNs topic (spec OPEN-QUESTIONS #3). **This is the first decision for you to make (§14).**

---

## 3. Users and what they can do

These are the client spec's personas, limited to the ones the management app is for. The rights come from the API's platform permission catalog.

| Persona | Platform role | What they manage |
|---|---|---|
| **Superadmin** (you, at first) | `superadmin` (protected) | Everything, including platform API keys, the application catalog, roles, and the new ops/config screens |
| **Support** | `support` | Users (read), access toggles, audit, tenants, billing (read) |
| **Billing admin** | `billing_admin` | Billing, refund authority, audit, users (read) |
| **App owner (developer)** | none: owns an Application | Their app's config, push credentials, app-scoped keys, webhooks, and grants confined to their app |
| **Custom narrow roles** | e.g. `support_readonly` | Defined in ROL-03 from the platform permission catalog |

The ops screens add new platform permissions (`ops.view`, `ops.manage`, `config.manage`). See api-gaps G-04 to G-06.

---

## 4. Information architecture

### iPhone

There are five tabs per the spec: **Home · Inbox · Orgs · Manage · Account**. During the admin-first milestones, the iPhone build opens to **Manage**, and the end-user tabs stay flag-gated until their milestone.

```
Manage (GLB-02 hub, grouped list, each row shows a count/health badge)
├── OPERATIONS                     ← new section, not in the client spec
│   ├── Overview          OPS-01   health, traffic, errors, latency, alarms
│   ├── Alarms            OPS-02   active + recent alarm history → OPS-03 detail
│   ├── Usage             OPS-04   by application, by API key, by operation
│   ├── Security events   OPS-05   sign-ins, failures, lockouts, 401/403, 429
│   └── System config     OPS-06   rate limits, feature flags, maintenance mode
├── ADMINISTRATION
│   ├── Users             USR-01 → USR-03 (tabs: Overview · Access ACX-01 · Roles ROL-04 · Sessions USR-04 · Notifications NTF-05 · Activity)
│   ├── Access            ACX-05
│   ├── Roles             ROL-01 → ROL-02
│   ├── Audit log         AUD-01 → AUD-02
│   └── Send notification NTF-06
└── DEVELOPER / PLATFORM
    ├── Applications      APL-01 → APL-03 (tabs: Overview · Settings schema · Permissions & roles · Keys · Webhooks · Push · Usage · Danger zone)
    ├── API keys          KEY-01 → KEY-04
    ├── Webhooks          WHK-01 → WHK-03 → WHK-04
    └── Tenants           BIL-04
```

### iPad

`TabView(.sidebarAdaptable)` shows the full tree in the sidebar, with `NavigationSplitView` list and detail panes. The Operations overview works as a full-width dashboard and stays readable in Split View at ⅓ width. It supports multiple windows: open a user's audit trail beside their access screen.

### Routes and deep links

The spec's routes stay as written. The new screens use `/ops`, `/ops/alarms/:alarmId`, `/ops/usage?app=…&key=…`, `/ops/security`, and `/ops/config`. An alarm push notification deep-links to `/ops/alarms/:alarmId`.

---

## 5. Feature set

Each feature is listed with its screens and the API calls behind it. ✅ marks existing endpoints and 🆕 marks endpoints proposed in api-gaps.md.

### 5.1 Operations overview (OPS-01): the landing screen for admins

- **Health strip.** `GET /health` ✅ plus a `GET /ops/status` 🆕 rollup: API, database ACU vs. max, webhook queue depth and DLQ count, push worker backlog, and the last deploy SHA and time.
- **Traffic, last 1h/24h/7d.** Request count, 4xx and 5xx rate, and p50/p95/p99 latency against the SLO lines (p95 < 150 ms on hot paths, p95 < 400 ms on everything else, 99.9% availability). Data comes from `GET /ops/metrics` 🆕 and is drawn with Swift Charts.
- **Active alarms** come from `GET /ops/alarms?state=ALARM` 🆕. Tapping one opens OPS-03.
- **Top movers:** top 5 applications and API keys by request volume and by error rate (`GET /ops/usage` 🆕).
- **Attention list:** unhealthy webhooks (`GET /webhooks` ✅ shows status and `consecutive_failures`), failed push credentials ✅, the app review queue (`GET /applications?review_status=pending_review` ✅), and keys expiring within 14 days (`GET /api-keys` ✅, filtered client-side on `expires_at`).
- **Cost guardrail:** month-to-date AWS spend against the $75 warn and $150 hard budgets, from `GET /ops/cost` 🆕.

### 5.2 Alarms and alerts (OPS-02 and OPS-03)

- List the alarms (`api_5xx`, `lambda_errors`, `lambda_throttles`, `aurora_near_max`, `webhook_dlq`, the `security-*` alarms, and the budget alarm) with state, reason and history.
- **Push to admins:** when an alarm changes state, every user holding `ops.view` gets a time-sensitive APNs push in category `ops.alarm`, with actions **Acknowledge** and **Open**. See api-gaps G-05 for the SNS → Lambda → platform-alert path.
- **Acknowledge or silence:** acknowledgement is recorded in audit as `ops.alarm_acknowledged`, and silencing for 1h, 4h or 24h is supported (🆕). Thresholds stay in Terraform, so the app reads them and doesn't edit them. Infrastructure changes go through PRs (§9).

### 5.3 Usage and analytics (OPS-04)

- Grouped by **application**, **API key** or **operation**: requests, error rate, p95 latency, and `429` count.
- A per-key drill-down shows `last_used_at` ✅, its rate-limit bucket, and its top operations and error codes.
- Business metrics come from existing list endpoints and need no new API: users by status, active entitlements per app (`GET /entitlements?application_id=…` ✅), Standard subscribers, and org seats.
- Exports share CSV through the share sheet (`ShareLink`, `Transferable`).

### 5.4 User and access administration (spec D6, D7, D8; all ✅)

- **Directory (USR-01):** search (`q`), filters for status, app, org and created date, cursor pagination, and multi-select bulk suspend (one request per row with 4 in parallel until a bulk endpoint exists; gap G-11).
- **User overview (USR-03):** profile, status, MFA state, platform roles, organizations, and plan.
- **Access (ACX-01 to ACX-05):** the AccessSwitch per app. It shows the resolved status first and every path (personal, org seat, platform-managed) one tap away, plus "Why?" explanations from `effective-permissions`. Writes send `If-Match` and `Idempotency-Key`.
- **Roles (ROL-01 to ROL-04):** list and create platform roles, edit permissions (seed roles are read-only), and assign or remove roles. The API blocks escalation (`role_escalation_forbidden`) and the UI explains it.
- **Sessions (USR-04):** list and revoke a user's sessions. **Force sign-out everywhere** for another user needs gap G-12. Today it means suspending them, or revoking sessions one at a time.
- **Security actions:** suspend or reactivate, reset MFA (`DELETE /users/{id}/mfa/totp` ✅), resend the invitation, data export, and erasure request. Each has a confirm dialog that names the object.
- **Activity tab:** the audit trail filtered by `target_user_id` ✅, merged with the user's security events (G-03 🆕).

### 5.5 Application management (spec D9, plus additions)

- **List (APL-01):** all applications with filters for review status, visibility, access tier and owner. A health dot shows when webhooks or push credentials are failing.
- **Register (APL-02):** `POST /applications` with slug, name, launch URL and owner. Slug validation runs client-side with the same regex. The confirm step warns that **the slug is permanent**.
- **Configure (APL-03, APL-04, APL-05):** redirect URIs, `settings_schema` (a structured editor plus a raw JSON view), the permission catalog, role names, and the default role.
- **Review (APL-06):** the queue, approve, reject (notes required), and suspend or reinstate.
- **Access and permissions:** the users with access, grants confined to this app, and the app's API keys and webhooks, all in tabs.
- **Usage tab:** OPS-04 filtered to this app.
- **Danger zone → Remove application:** needs gap G-02. Until then, the app offers **Suspend** (which blocks new grants and new app tokens) and explains that permanent removal isn't available yet.

### 5.6 API key management (spec D10, ✅)

How keys are handled on the client:

- **The app never holds an API key.** Admins act through their own platform session, using a user token. The API forbids API keys from managing keys (`user_token_required`), and putting a platform key on a phone would create a long-lived credential that can be lost with the device. API keys are for servers and agents only.
- **Create (KEY-02):** set the scope (platform or one application), permissions (only those valid for the scope, from `GET /permissions`), mode, intended use, and expiry. Defaults: `test` mode when the scope is a test application, `restrict_destructive` on for agent keys, and an expiry of 1 year.
- **Secret reveal (KEY-03):** the secret is shown once, in a sheet that can't be dismissed by swiping. It's hidden in the app-switcher snapshot and blanked while the screen is recorded. Copy writes to the pasteboard with a 60-second local-only expiry, using `UIPasteboard` `.expirationDate` and `.localOnly` so it doesn't travel by Universal Clipboard. The share sheet is offered only for AirDrop or a password manager. The secret is never cached or logged.
- **Rotate:** the guided flow is **zero-downtime rotation**, the API's recommended path: create a replacement key, cut the service over, confirm the old key's `last_used_at` stops advancing, then revoke the old key. In-place `rotate` is also available, with a warning that the old secret dies immediately.
- **Hygiene view:** keys never used, keys idle for 90+ days, agent keys with `restrict_destructive` off (audited), and keys close to expiry.

### 5.7 Webhooks, push and integrations (spec WHK-*, APL-07, ✅)

- Webhook list with health, delivery log, redeliver, send test, and rotate signing secret (shown once, like key secrets).
- Push credentials per application (APNs, FCM, Web Push), with status and failures.

### 5.8 Audit log (spec D12, ✅)

- Filters: actor, action (multi), target, application, organization, tenant, and time range. Shows the `Audit-Hot-Window-Start` boundary.
- Event detail shows a before/after diff and the request ID, and links to the actor and target.
- **Saved investigations:** filter presets stored on the device. Export is behind `audit_export`, which is Phase 3 in the API (gap G-13).

### 5.9 System configuration (OPS-06, needs G-06)

- **Rate limits:** read the defaults, and set per-operation and per-key overrides. NFR → Rate limiting already calls for raising per-key limits for billing integrations.
- **Feature flags:** server-driven flags for the client (`notifications`, `billing`, `organizations`, `audit_export`, …), replacing hard-coded defaults. The spec's "501 turns a flag off" fallback stays.
- **Maintenance mode:** writes return `503`, and reads still work.
- **Email sender and support URL defaults.**
- Every change requires step-up auth (§6), sends `If-Match`, and writes an audit event `config.updated` with before and after values.

### 5.10 Notifications (spec D13, ✅)

- NTF-06 sends a platform notification to a user. NTF-05 shows a user's notifications and devices for support.
- The admin's own inbox shows ops alarms (`ops.alarm`), security alerts, and account alerts.

---

## 6. Authentication and security model for the app

| Concern | Design |
|---|---|
| Sign-in | Embedded flow: `POST /auth/login` → `mfa_required` → `POST /auth/mfa/verify`. This is acceptable because the app is first-party (Trust Model). Hosted PKCE comes later, after `auth.substratalapps.com` exists. |
| Tokens | Access token (15 min) in memory only. Refresh token (rotating, 30d idle / 90d absolute) in the Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. That's stricter than the spec's `AfterFirstUnlock`, because admin sessions shouldn't refresh while the phone is locked. Refresh is single-flight: a reused refresh token revokes the session. |
| MFA | **Required for anyone with platform permissions.** The client enforces it now: an admin without TOTP who signs in is sent to ACC-05 before the Manage tab unlocks. The server should enforce it too (G-07). `amr` in the access token shows whether `otp` was used. |
| Device lock | Face ID / Touch ID is required to open the app when the user holds any platform permission (`LAContext`, `.deviceOwnerAuthentication`). The app re-locks after 5 minutes in the background or 15 minutes idle (spec NFR §3). |
| Step-up | Destructive or credential actions (create or rotate a platform key, assign `superadmin`, remove an application, change system config, reset MFA) need Face ID on the device now. Server-side step-up comes with G-08. |
| Privacy | Admin data is held in memory only (spec §7). The app blurs on `scenePhase != .active`, and secrets are hidden while `UIScreen.isCaptured`. No PII, tokens or notification content goes into logs. |
| Lost device | Another admin revokes the session (USR-04). A sign-out on a device deactivates its push registrations server-side. |
| Network | ATS defaults with TLS 1.2+. Certificate pinning is optional. **Not recommended** at first, because the API Gateway/ACM certificate rotates. Pin the Amazon root CA if you want it. |

---

## 7. iOS technology stack

| Concern | Choice | Why |
|---|---|---|
| Language and UI | **Swift 6** (strict concurrency), **SwiftUI**, **iOS 17 minimum** (per spec) with the iOS 26 SDK | Native, matches the spec, Liquid Glass through standard components. iOS 17 gives `@Observable`, SwiftData and the newer `TabView`/charts APIs. |
| State | `@Observable` stores per feature, plus an app-wide `Capabilities` store | Simple, no third-party architecture framework. Add TCA only if the team already uses it. |
| API client | **`swift-openapi-generator`** with `OpenAPIURLSession`, generated from `openapi.yaml` (3.1) at build time by the SwiftPM plugin | Follows the spec's "screens never call HTTP directly" rule. The generated client drifts only when the spec changes. |
| PATCH semantics | A hand-written `Patch<T>` tri-state (`absent / null / value`) for PATCH bodies | The API needs explicit `null` and field presence on PATCH. Generated optionals can't express that, which is the same reason the Go server writes its bodies by hand. |
| Middleware | Bearer auth with single-flight refresh, `Idempotency-Key` injection, `If-Match`/`ETag` store, `Retry-After`/`429` backoff, `X-Request-Id` capture, `501` → feature-flag-off | Every rule in CLIENT-ARCHITECTURE §4 lives in one layer. |
| Charts | **Swift Charts** | Built in, accessible (Audio Graphs), themeable, no dependency. |
| Storage | Keychain for the refresh token. SwiftData or files with `NSFileProtectionComplete` for non-admin caches only. | Admin data stays in memory (spec §7). |
| Push | APNs through the API's own push pipeline as `app_hub`. **No Firebase or third-party push SDK.** | Free, and it's already built server-side. |
| Crash and performance | **MetricKit** plus Xcode Organizer. No third-party SDK at first. | Free and private. Add a hosted crash service only if Organizer's data turns out too thin. |
| Shared code | A `SubstratalKit` Swift package (API client, Session, Capabilities, Theme, models) used by iOS now and macOS later | Per the spec. |
| Dependencies | `swift-openapi-generator`, `swift-openapi-runtime`, `swift-openapi-urlsession`, and `swift-collections` if needed. Nothing else. | Fewer dependencies mean less churn and less supply-chain risk. |
| Testing | Swift Testing for units, XCUITest for the persona matrix, and snapshot tests of key screens in the 2 default themes | |
| CI/CD | **Xcode Cloud** (25 compute hours a month are included with the $99/yr Developer Program) builds every PR and ships `main` to TestFlight | GitHub-hosted macOS runners cost 10× the Linux rate, and Xcode Cloud fits the free allowance at this team size. |
| Environments | Build configs: `Debug-Local` (devserver at `localhost:8080`), `Debug-Prod-Test` (prod with test-mode sign-in), and `Release` | There's no staging API by design (one AWS account at Tier 0). The API's test mode is the sandbox. |
| Distribution | TestFlight for admins first, then the App Store (universal) once end-user screens ship. Use Apple Business Manager custom-app distribution if you choose the separate admin-only app. | |

### Project layout

```
substratalapps-ios/
├── App/                         SubstratalHub (iOS target): App, scenes, routing, tabs
├── Features/                    one folder per domain: Ops, Users, Access, Roles, Audit,
│                                Applications, Keys, Webhooks, Notifications, Account, Auth
├── Packages/SubstratalKit/
│   ├── Sources/API/             openapi.yaml (vendored + checksum) → generated client, middleware
│   ├── Sources/Session/         login, MFA, refresh, Keychain, biometric lock
│   ├── Sources/Capabilities/    permission gating
│   ├── Sources/Theme/           SubstratalTheme.swift from the spec package
│   └── Sources/Models/          Patch<T>, ID prefixes, enums with unknown-case fallback
├── Extensions/NotificationService/   notification service extension (category actions)
├── Tests/  UITests/
├── design/                      theme exploration (existing)
└── docs/                        this plan, api-gaps.md
```

Enums must decode unknown values to an `.unknown(String)` case. The API's versioning rules make adding enum values a non-breaking change.

---

## 8. AWS architecture and cost

**The iOS app adds no always-on infrastructure.** It calls `api.substratalapps.com` directly. CORS doesn't apply to a native client, so the browser-only BFF the web spec needs (OPEN-QUESTIONS #14) isn't needed here. The new server pieces fit into the existing Lambda functions and Aurora:

```
iPhone/iPad ──HTTPS──► API Gateway (HTTP API) ──► API Lambda (Go)
                                                   ├─ existing 118 operations → Aurora (Data API)
                                                   ├─ /ops/metrics, /status  → CloudWatch GetMetricData (60 s in-memory cache)
                                                   ├─ /ops/alarms            → CloudWatch DescribeAlarms
                                                   ├─ /ops/usage             → Aurora usage_hourly rollup table
                                                   ├─ /ops/cost              → Cost Explorer (cached 6 h, $0.01/call)
                                                   └─ /system/config         → Aurora system_config (cached 60 s)
Jobs Lambda (existing, hourly) ── Logs Insights query over the API log group ──► usage_hourly, security_events
CloudWatch alarms ─► SNS alarms topic (existing) ─► ops-alert Lambda (new, tiny) ─► platform alert → APNs via app_hub
S3 + CloudFront (new) ─► dashboard.substratalapps.com: apple-app-site-association + verify/reset/invite pages
```

| New item | Approx. monthly cost at Tier 0 |
|---|---|
| CloudWatch `GetMetricData`: about 20 metrics per dashboard load, cached 60 s | Under $1 at admin-scale use ($0.01 per 1,000 metrics requested) |
| Logs Insights hourly rollup | Cents. $0.005 per GB scanned, and Tier 0 logs are MB-scale. |
| Cost Explorer API, cached 6 h | About $1.20 (4 calls a day at $0.01) |
| ops-alert Lambda plus SNS fan-out | ~$0, within the free tier |
| `dashboard.substratalapps.com` static site (S3 + CloudFront + ACM) | ~$0 to $1 |
| Aurora rows for rollups and config | ~$0, within the existing floor |
| **Total added** | **About $1 to $3 a month** on top of the $45 to $55 floor |
| Apple Developer Program | $99/year (Xcode Cloud's 25 h/month is included) |

Things to avoid: a per-request write to Aurora for usage, which adds latency and cost on the hot path; high-cardinality custom CloudWatch metrics per key, at $0.30 per metric per month, which grow with the key count; Amazon Managed Grafana at $9+ per user per month; a NAT gateway; and a second API environment.

---

## 9. Integrations

| Integration | How | Cost |
|---|---|---|
| Slack or Teams alarm channel | Point the existing SNS alarms topic at AWS Chatbot | Free |
| PagerDuty or Opsgenie | SNS → their HTTPS endpoint, or an EventBridge rule | Vendor plan |
| Downstream systems reacting to domain events | Webhooks (✅): `access.revoked`, `role.removed`, `user.*`, `application.*`, … | — |
| AI assistants | The MCP server (✅) with an `agent` key that has `restrict_destructive` on. The app can create such keys with the safe preset. | — |
| Billing | Stripe portal and refunds stay in Stripe. The app links out (`billing.manage`). | — |
| Infrastructure changes | Terraform through GitHub PRs. The app shows the deploy SHA and links to the release PR, but it doesn't run deploys. | — |
| Shortcuts and Siri | App Intents for "Turn off access for {person} in {app}" (with confirmation) and "Show API health" | — |
| Widgets | A Home or Lock Screen widget for API health (5xx rate and active alarms), refreshed by a silent push on alarm state changes plus a timeline every 30 min | — |

---

## 10. Design system

- Use the spec's themes from `ios/theme/SubstratalTheme.swift`: 5 light and 5 dark, with Moss Paper and Forest Floor as defaults. SET-01 offers the choice.
- `design/theme-options.html` in this repo proposes a **different** set of six themes (Bedrock, Quartz, Lichen, Strata, Obsidian, Basalt). One set has to win, or the spec's `THEMES.md` gets updated. This is decision §14-3.
- Operations screens use the existing status semantics (`status-semantics.json`) for ok/warn/fail, never color alone. Each chart has an accessible summary and Audio Graph support.
- Use SF Symbols per INFORMATION-ARCHITECTURE §5. Suggested symbols for the new sections: Operations `waveform.path.ecg`, Alarms `bell.badge`, Usage `chart.bar.xaxis`, Security events `lock.shield`, System config `slider.horizontal.below.square.and.square.filled`.

---

## 11. Milestones

Each milestone is shippable through TestFlight.

| # | Milestone | Content | API dependencies |
|---|---|---|---|
| M0 | Foundations (1–2 wk) | Xcode project, `SubstratalKit`, generated client plus middleware, Session (login, MFA, refresh, Keychain, biometric lock), Capabilities, theming, Manage hub shell, Xcode Cloud → TestFlight | None. Ops: set the superadmin password and enroll TOTP. |
| M1 | Core admin (3–4 wk) | Users, Access, Roles, Audit, Sessions, MFA reset. Bulk actions client-side. | None (all ✅) |
| M2 | Platform admin (2–3 wk) | Applications (register, configure, review, suspend), API keys (create, reveal, zero-downtime rotation, hygiene), Webhooks, Push credentials, Tenants | G-01 (email-link domain) to send invitations for real |
| M3 | Operations (3 wk) | OPS-01 overview, OPS-02/03 alarms with push, OPS-04 usage, OPS-05 security events | G-03, G-04, G-05; `app_hub` registered with APNs |
| M4 | Config and hardening (2 wk) | OPS-06 system config, server-side MFA requirement, step-up, application removal, widgets, App Intents | G-02, G-06, G-07, G-08 |
| M5 | End-user Hub (later) | Home, Inbox, Orgs, Account, Plan & Billing, so the iOS Hub matches the full spec | Billing upgrade on iOS stays off pending App Store policy (spec OPEN-QUESTIONS #10) |

These assume one experienced iOS developer working with AI assistance. API work for M3 and M4 runs in parallel in the Go repo.

---

## 12. Testing and acceptance

- **Persona matrix:** a test account per persona, in both test mode and live mode. Check that the tab set and every action match Capabilities.
- **Contract:** decode real responses captured from the devserver (`make dev` in the API repo), and fail on unknown fields only in debug builds.
- **Security:** no secrets in logs (CI greps for `satk_`, `rtk_` and `eyJ` in captured logs), a screenshot/recording test on KEY-03, and Keychain wiped on sign-out.
- **Resilience:** 401 refresh replay, 409 `version_conflict` reload/re-apply, 429 countdown, 503 banner, and offline.
- **Accessibility:** VoiceOver, Dynamic Type at AX5, and charts with Audio Graphs.
- **Performance:** cold start to Manage in ≤ 1.5 s, and 60/120 fps scroll on a 10k-row audit list.

---

## 13. Risks

| Risk | Mitigation |
|---|---|
| A lost phone holding superadmin power | Required MFA, biometric lock, Keychain `WhenUnlockedThisDeviceOnly`, server-side MFA enforcement (G-07), and a second superadmin able to revoke sessions |
| App Store review of an admin-heavy app | Provide a demo account with a non-superadmin custom role. A separate admin app could use custom-app distribution instead. |
| The client spec drifts from the API: the spec still says notifications return `501` and calls the API "v1.4.0", while the API docs never use that number and notifications shipped 2026-10-18 | Vendor `openapi.yaml` with a checksum and regenerate on a schedule. Update the spec (api-gaps "Spec drift"). |
| Usage metrics lag by an hour | The overview combines near-real-time CloudWatch metrics (1-min resolution) with the hourly rollups for per-app and per-key breakdowns. Label the freshness on screen. |

---

## 14. Decisions needed from you

1. **One Hub app built admin-first (recommended), or a separate admin-only app?**
2. **Distribution:** TestFlight-only for admins, or the App Store from the start?
3. **Themes:** the spec's 5+5 (Moss Paper / Forest Floor), or the six in `design/theme-options.html`?
4. **Application removal semantics** (api-gaps G-02): soft archive (recommended) or hard delete?
5. **Ops permissions:** new `ops.view` / `config.manage` permissions, or reuse `audit.view` / superadmin-only?
