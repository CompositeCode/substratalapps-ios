# API gaps for the iOS app

What the iOS Hub needs from the Platform API, as of 2026-10-23 (`openapi.yaml` `1.0.0-draft.9`, 124 operations,
`Substratal-Version: 1`). Gaps are tracked as [`[api-gaps]` issues in the API repository](https://github.com/CompositeCode/substratalapps.com/issues?q=is%3Aissue+%22%5Bapi-gaps%5D%22),
shared with the web and other Hub apps. This file maps the gaps first listed here (2026-10-21) onto those issues and
adds what building the iOS client turned up.

## Mapping to the API's issues

| First listed here | Issue | Status | Effect on iOS |
|---|---|---|---|
| G-01 `dashboard.substratalapps.com` doesn't resolve | [#39](https://github.com/CompositeCode/substratalapps.com/issues/39) go-live steps; the dashboard pages are built by the web Hub | Open. The domain still doesn't resolve on 2026-10-23. | Universal Links and `webcredentials` need the domain's `apple-app-site-association`. Until then, emailed links can't open the app, and `substratal://` links work only when typed or tapped in-app. |
| G-02 Application removal | [#52](https://github.com/CompositeCode/substratalapps.com/issues/52) G15 | Open | APL-03 offers Suspend only |
| G-03 Security events API | [#42](https://github.com/CompositeCode/substratalapps.com/issues/42) G5, [#43](https://github.com/CompositeCode/substratalapps.com/issues/43) G6 | Open | Console screen SEC-01 is web-only (OPEN-QUESTIONS #27) |
| G-04 Metrics and usage | [#44](https://github.com/CompositeCode/substratalapps.com/issues/44) G7, [#53](https://github.com/CompositeCode/substratalapps.com/issues/53) G16 | Open | Web-only console |
| G-05 Alarms to admins' devices | Web Ops gateway (no API issue) | — | Not on iOS. Alarm email, and AWS Chatbot to Slack, remain the phone path. |
| G-06 System configuration and flags | [#48](https://github.com/CompositeCode/substratalapps.com/issues/48) G11 | Open | iOS flags default per spec. A `501` turns a feature off. |
| G-07 / G-08 Staff MFA and step-up | [#50](https://github.com/CompositeCode/substratalapps.com/issues/50) G13 | Open | Help pages say two-factor is recommended, not enforced |
| G-09 One call for "my permissions" | Not tracked | — | Capabilities uses the spec's six-call recipe. Propose `GET /users/me/permissions`. |
| G-10 `GET /users?role_id=` | [#54](https://github.com/CompositeCode/substratalapps.com/issues/54) G17 | **Done** (draft.9) | Wired into `UserQuery.roleIDs`. ROL-02 links to "People with this role". |
| G-11 Bulk operations | [#55](https://github.com/CompositeCode/substratalapps.com/issues/55) G18 | Deferred | Client fans out, 4 requests at a time |
| G-12 Revoke all of a user's sessions | [#51](https://github.com/CompositeCode/substratalapps.com/issues/51) G14 | **Done** (draft.9) | `auth_revokeAllSessions` is generated. USR-04 will use it. |
| G-13 Audit export | [#56](https://github.com/CompositeCode/substratalapps.com/issues/56), [#33](https://github.com/CompositeCode/substratalapps.com/issues/33) | **Done** (draft.8) | AUD-01 export is next |
| G-14 Per-key rate-limit overrides | [#49](https://github.com/CompositeCode/substratalapps.com/issues/49) G12 | Open | — |
| G-15 Asset upload | Not tracked (specs OPEN-QUESTIONS #1) | — | Avatars and icons show initials |
| G-16 `app_hub` and push | [#25](https://github.com/CompositeCode/substratalapps.com/issues/25), [#24](https://github.com/CompositeCode/substratalapps.com/issues/24) | Open | Push registration (NTF-03/04) waits on these |

## Found while generating the Swift client

`swift-openapi-generator` 1.14 builds all 124 operations. To make the generated client honour the API's contract,
`scripts/derive-openapi.py` adjusts the copy it reads (the vendored original in `api-contract/` is untouched):

| Finding | Why it matters | Workaround here | Suggested fix in `openapi.yaml` |
|---|---|---|---|
| String enums become frozen Swift enums | One new enum value would fail decoding of a whole response, which breaks the API's own rule that enums grow without a version bump | Enums are removed from the derived copy. The domain layer maps strings, with an `unknown` case. | Document `x-extensible-enum`, or keep enums but note the rule in `info.description` for generator users |
| Nullable `oneOf: [X, {type: "null"}]` is skipped | Ten properties were dropped from the generated types (for example `Subscription.member_scope`, `Device.inactive_reason`, `UserRoleAssignment.assigned_by`) | Unwrapped to `X`, and dropped from `required` | Express nullability as `type: [object, "null"]` with `$ref` in `allOf`, or leave nullable properties out of `required` |
| `required` names properties defined only in a sibling `allOf` branch | Six warnings (for example `applications.create` `slug`, `name`, `launch_url`; `PageEnvelope.data`) | None needed: the properties are still generated from the other branch | Move `required` next to the `properties` it names |
| The `Substratal-Version` parameter on every operation | Every generated call would need the header passed by hand | Stripped from the derived copy. `APIVersionMiddleware` sends it on every request. | None needed. Declaring it is correct, and clients should set it in middleware. |
