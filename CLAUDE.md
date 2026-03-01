# MUT (Mass Update Tool) — SwiftUI Rewrite

## Project Overview

MUT is a macOS application for Jamf Pro administrators. It enables mass updates to managed devices and records by uploading CSV files. This is a ground-up rewrite of the original MUT app, moving from AppKit/Swift to SwiftUI.

### What MUT Does

- Mass updates to **iOS device inventory** attributes
- Mass updates to **macOS device inventory** attributes
- Mass updates to **user records**
- Mass updates to **PreStage Enrollments**
- Mass updates to **group membership** (static groups)
- Reads a user-provided `.csv` file containing device/user identifiers and the values to update
- Communicates with the **Jamf Pro API** to apply changes

### Target Platform

- **macOS** (primary) + **iPad** via "Designed for iPad" / Mac Catalyst
- Minimum deployment: **macOS 14 (Sonoma)** / **iPadOS 17**
- Build as a macOS app first; iPad support comes via Catalyst with minimal platform conditionals
- File picking: use `fileImporter` modifier (works on both platforms)

## Architecture & Conventions

### Language & Frameworks

- **Swift 6** with strict concurrency enabled
- **SwiftUI** for all UI
- **Swift Package Manager** for dependencies
- Minimum deployment target: **macOS 14 (Sonoma)**

### Project Structure

Xcode project: `mut-universal.xcodeproj`
Bundle ID: `com.mlev.mut-universal`

```
mut-universal/              # Main app source (Xcode group)
├── App/                    # App entry point, app-level config
├── Models/                 # Data models (devices, users, groups, CSV rows, API types)
├── Views/                  # SwiftUI views, organized by feature
│   ├── CSV/                # CSV import and preview
│   ├── Auth/               # Jamf Pro authentication
│   ├── Updates/            # Update progress and results
│   └── Settings/           # App settings/preferences
├── ViewModels/             # @Observable view models
├── Services/               # Business logic and API communication
│   ├── JamfProAPI/         # Jamf Pro API client, token management
│   ├── CSVParser/          # CSV parsing and validation
│   ├── Keychain/           # Keychain storage for client credentials
│   └── UpdateEngine/       # Orchestrates batch updates
├── Utilities/              # Shared helpers, extensions
├── Resources/              # Assets, localization
└── Assets.xcassets/        # App icon, accent color, images
mut-universalTests/         # Unit tests (Swift Testing)
mut-universalUITests/       # UI tests (XCTest)
```

### Coding Conventions

- Use `async/await` and structured concurrency — no Combine unless wrapping a system API that requires it
- Prefer value types (`struct`, `enum`) over classes where possible
- View models are `@Observable` classes (Observation framework, not ObservableObject)
- Use SwiftUI environment for dependency injection
- Keep views thin — logic belongs in view models or services
- Name files after the primary type they contain
- One public type per file (small private helpers in the same file are fine)

### Jamf Pro API Notes

- **API docs:** https://developer.jamf.com/jamf-pro/docs/jamf-pro-api-overview
- **Primary API:** Jamf Pro API (v1/v2) at `/api/v1/...`, `/api/v2/...` — use this for everything possible
- **Classic API fallback:** Only use the Classic API (`/JSSResource/...`) for operations not yet available in the Jamf Pro API (see table below)
- Both APIs use the same Bearer token, so a single auth flow covers both

#### Authentication

- Uses **OAuth Client Credentials** flow (client ID + client secret)
- Token endpoint: `POST /api/oauth/token` with `grant_type=client_credentials`
- Tokens expire (typically 1800s / 30 min) — **no refresh tokens**, must re-request with client ID/secret
- Cannot use `/v1/auth/keep-alive` with client-credentials tokens
- Invalidate with `POST /api/v1/auth/invalidate-token`
- Client ID/secret are created in Jamf Pro under Settings > System > API Roles and Clients

#### Auth UX Flow

1. Login screen: user enters Jamf Pro URL + client ID + client secret
2. Optional "Remember me" checkbox — stores client ID/secret in **macOS Keychain** if checked
3. App attempts to obtain a Bearer token before proceeding
4. On success → navigate to main interface; on failure → show error on login screen
5. Token auto-renewal: re-request token before expiry using stored credentials

#### Key Endpoints

| Operation | API | Endpoint |
|---|---|---|
| Update macOS computer inventory | Jamf Pro API | `PATCH /api/v1/computers-inventory-detail/{id}` |
| Update iOS device inventory | Jamf Pro API | `PATCH /api/v2/mobile-devices/{id}` |
| Look up computer by serial | Jamf Pro API | `GET /api/v1/computers-inventory?section=GENERAL&filter=hardware.serialNumber=={serial}` |
| PreStage enrollment scope | Jamf Pro API | `POST /api/v2/{computer,mobile-device}-prestages/{id}/scope` |
| Mobile device static groups | Jamf Pro API | `PATCH /api/v1/mobile-device-groups/static-groups/{id}` |
| Computer static groups (membership) | Classic API | `PUT /JSSResource/computergroups/id/{id}` |
| User record updates | Classic API | `PUT /JSSResource/users/id/{id}` |
| iOS device name enforcement (MDM) | Classic API | `POST /JSSResource/mobiledevicecommands/command/DeviceName/{name}/id/{id}` |

#### MVP Scope (Jamf Pro API only)

- Update inventory fields (asset tag, username, full name, building, department, purchasing info) on macOS and iOS devices
- Enforce device name on iOS devices (requires Classic API fallback for MDM command)

#### Rate Limiting

- Use concurrency limits (max 5 concurrent requests)
- All API errors should surface clearly to the user with the Jamf Pro error message

### CSV Handling

- Support standard RFC 4180 CSV
- First row is always a header row
- The first column is always the identifier (serial number, asset tag, username, etc.)
- Validate CSV structure before beginning updates
- Show a preview of parsed data before the user confirms

### Error Handling

- Never silently swallow errors
- Use typed errors (`enum MUTError: LocalizedError`)
- Present errors to the user in a clear, actionable way
- Log detailed error info for debugging (use `os.Logger`)

### Testing

- Unit tests for services, models, and view models
- Use Swift Testing framework (`@Test`, `#expect`) not XCTest for new tests
- Mock the Jamf Pro API layer for testing — use protocol-based abstraction

## Scratchpads

**Always write plans, research, and working notes to files in `.claude/scratchpads/`.** This is critical for surviving context compaction and for coordination across agent teammates.

### When to write a scratchpad

- **Before starting a task:** Write your plan/approach to a scratchpad file before writing code
- **During research:** Capture API findings, code patterns discovered, or architecture decisions
- **When a task is complex:** Break down your thinking into a scratchpad so it persists even if context is compacted
- **When coordinating with teammates:** Write status updates and findings other agents can read

### Naming convention

Use descriptive filenames: `.claude/scratchpads/{topic}-{date}.md`
- `api-auth-research-2026-02-28.md`
- `csv-parser-plan.md`
- `update-engine-design.md`

### What to include

- Current plan and approach
- Key decisions made and why
- Blockers or open questions
- Findings from code exploration or API research
- Status of in-progress work

Scratchpads are disposable working documents — don't worry about polish. The goal is to externalize your thinking so it's never lost to compaction.

## Agent Teams

This project uses Claude Code agent teams for parallel development. When spawning teammates:

- Assign each teammate a **distinct set of files** to avoid merge conflicts
- Good team splits for this project:
  - **API teammate**: `mut-universal/Services/JamfProAPI/` — API client, auth, token management
  - **CSV teammate**: `mut-universal/Services/CSVParser/`, `mut-universal/Views/CSV/` — parsing, validation, preview
  - **UI teammate**: `mut-universal/Views/`, `mut-universal/ViewModels/` — screens, navigation, layout
  - **Engine teammate**: `mut-universal/Services/UpdateEngine/` — batch update orchestration, progress tracking
- Always require **plan approval** before teammates make changes to shared types in `Models/`
- Teammates should run tests relevant to their area before completing

## Git Conventions

- Commit messages: imperative mood, concise (e.g., "Add CSV parser with validation")
- Branch names: `feature/description`, `fix/description`, `refactor/description`
- Keep commits focused — one logical change per commit
