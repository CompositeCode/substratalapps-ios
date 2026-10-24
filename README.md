# Substratal Hub for iOS and iPadOS

The native iOS/iPadOS client of the [Substratal Apps Platform API](https://compositecode.github.io/substratalapps.com/):
the management app for the platform (users, access, roles, applications, API keys, webhooks, audit), and in time the
full Substratal Hub for every user. It's built from the shared
[Hub specifications](https://compositecode.github.io/substratalapps-applications-specs/) and links to the shared
[help center](https://compositecode.github.io/substratalapps-applications-specs/help/).

- **Plan:** [docs/management-app-plan.md](docs/management-app-plan.md)
- **API gaps:** [docs/api-gaps.md](docs/api-gaps.md), which maps to the API repo's `[api-gaps]` issues

## Requirements

- Xcode 27 (Swift 6.4, iOS 26 SDK). Deployment target **iOS 17**.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) only if you change `project.yml` (`brew install xcodegen`).
  The generated `SubstratalHub.xcodeproj` is committed.
- Python 3 with PyYAML (installed on demand), only to re-sync the API contract.

## Run it

```bash
open SubstratalHub.xcodeproj    # trust the OpenAPIGenerator plugin when Xcode asks, then Run
```

The app talks to production (`https://api.substratalapps.com`) by default. To explore without an account, run with
**demo data**: Edit Scheme → Run → Arguments → enable `-demo YES`. Or from the command line:

```bash
make build
xcrun simctl launch booted com.substratalapps.hub -demo YES -autoSignIn YES -route /admin/users
```

`-autoSignIn YES` skips sign-in, and `-route <path>` opens any Hub route as if it were a deep link. Both work in demo
mode only. In demo mode, any password and any 6-digit code sign you in as a superadmin.

## API versioning

The Platform API has **no version in its URLs**. Every path is at the host root (`/users`, not `/v1/users`), and
`/v1/…` returns `404`. The version goes in a request header:

```http
Substratal-Version: 1
```

- `APIConfiguration.apiVersion` pins the version this build speaks. `APIVersionMiddleware` sends it on every request,
  and the generated client never passes it per call.
- A `Deprecation`/`Sunset` response shows the GLB-03 **Update available** banner. `400 unsupported_api_version`
  stops API traffic and shows **Update required** (`APIVersionMonitor`).
- `contractVersion` (the `openapi.yaml` `info.version`, now `1.0.0-draft.9`) is a separate thing, shown on
  Account → About.
- A unit test fails if the pinned header value isn't one the vendored contract declares.

See the help center's [API versioning](https://compositecode.github.io/substratalapps-applications-specs/help/developers/api-versioning.html) page.

## Layout

```
App/                          the iOS app target
  SubstratalHubApp.swift      entry point; AppEnvironment wires live or demo services
  Shell/                      sections (INFORMATION-ARCHITECTURE), tabs / iPad sidebar, Navigator (deep links), ScreenView (route → screen)
  Features/                   screens by domain: Auth, Home, Inbox, Account, Users, Roles, Audit, Applications, Keys
  Resources/Assets.xcassets   brand assets and app icon from the specs package
Packages/SubstratalKit/       shared with the future macOS app
  SubstratalAPI               client generated from openapi.yaml at build time (swift-openapi-generator)
  SubstratalCore              middleware (version, auth + single-flight refresh, errors, idempotency), session, Keychain,
                              Capabilities, domain models, ScreenID (all 75 screens) and Route parsing, HelpCenter links
  SubstratalUI                theme (5 light + 5 dark), StatusBadge, IDChip, AccessRow, SecretRevealSheet, state views
api-contract/                 the untouched upstream openapi.yaml, and CONTRACT.json (where it came from, its hash, its version)
scripts/                      sync-openapi.sh, derive-openapi.py, generate-screen-ids.py
UITests/                      smoke test against demo data
```

## What's built

| Area | Status |
|---|---|
| Shell | iPhone: Home · Inbox · Orgs · Manage · Account (Manage hidden without rights). iPad (iOS 18+): sidebar with the full tree. Every one of the 75 routes resolves from deep links, `substratal://` and Universal Links. Unbuilt screens show a placeholder that links to their spec and help. |
| Sign-in | AUTH-01, AUTH-02 (live: login, MFA, Keychain session restore, single-flight refresh, sign out, sign out everywhere) |
| Administration | USR-01 (search, status filter, paging), USR-03 (overview, access with AccessRow), ROL-01/02, AUD-01/02 |
| Developer | APL-01/03, KEY-01 (list, revoke), KEY-02 → KEY-03 (create, then a one-time secret reveal hidden from capture, with a 60 s local-only clipboard) |
| Personal | APP-01 Home grid, ACC-01 Account (with help links and About), SET-01 appearance and themes |
| Not yet | Write paths behind the access switch (ACX-03), the remaining forms, push registration (waits on `app_hub` and APNs credentials, API issues #24/#25), biometric lock, widgets, App Intents |

## Keeping in sync

| What | How |
|---|---|
| API contract | `make contract`, or the daily **API contract sync** workflow, which opens a PR when `openapi.yaml` changes |
| Screen registry | `make screens` regenerates `ScreenID.swift` from the specs (the same workflow runs it) |
| Xcode project | Edit `project.yml`, then `make project`. CI fails if the committed project doesn't match. |
| Help center | Merging to `main` sends `app-docs-updated` to the specs repo (**Help center rebuild** workflow; needs the `SPECS_DOCS_TOKEN` secret). The help center also rebuilds daily. |

## Tests

```bash
make test-kit    # routing, versioning middleware, contract pin, status mapping (swift test)
make test-ui     # sign-in → two-factor → shell, against demo data
```
