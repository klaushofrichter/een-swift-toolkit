# EEN Swift Toolkit

A native Swift SDK for the [Eagle Eye Networks](https://www.een.com) REST API v3.0. Provides type-safe access to all 16 API resource domains with full async/await support.

## Requirements

- iOS 16+ / macOS 13+
- Swift 5.9+
- No external dependencies

## Installation

Add the package via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/klaushofrichter/een-swift-toolkit.git", from: "0.1.0")
]
```

Then add `EENApiToolkit` to your target's dependencies.

## Quick Start

```swift
import EENApiToolkit

let config = EENToolkitConfig(
    proxyUrl: "http://127.0.0.1:3333",
    clientId: "YOUR_CLIENT_ID",
    redirectUri: "http://127.0.0.1:3333",
    storageStrategy: .keychain
)
let toolkit = EENToolkit(config: config)

// Authenticate via OAuth proxy
let authUrl = await toolkit.auth.getAuthUrl()
// ... present login UI, handle callback ...

// Fetch cameras
var params = ListCamerasParams(pageSize: 20)
params.include = ["deviceInfo", "status"]
let cameras = try await toolkit.cameras.list(params: params)
for camera in cameras.results {
    print(camera.name)
}
```

## Architecture

| Component | Role |
|-----------|------|
| `EENToolkit` | Central entry point with service properties (`toolkit.cameras`, `toolkit.events`, etc.) |
| `HTTPClient` | Actor wrapping URLSession for thread-safe networking |
| `AuthManager` | Actor handling OAuth proxy flow (getAuthUrl, handleCallback, refreshToken, revokeToken) |
| `AuthState` | `@MainActor ObservableObject` for SwiftUI auth state binding |
| `TokenStorage` | Protocol with Keychain and InMemory implementations |
| `PaginatedResult<T>` | Generic paginated response wrapper (normalizes empty-string tokens to nil) |
| `SSEClient` | Server-Sent Events via URLSessionDataDelegate |

### Concurrency Model

- **HTTPClient** — actor (thread-safe networking)
- **AuthManager** — actor (token lifecycle)
- **AuthState** — @MainActor (UI binding)
- **Services** — Sendable structs (stateless, safe to share)

## API Services

All services use `async throws` and return `Codable`, `Sendable`, `Identifiable` models.

| Service | Resource |
|---------|----------|
| `AlertService` | Alerts |
| `AutomationService` | Automations |
| `BridgeService` | Bridges |
| `CameraService` | Cameras |
| `DownloadService` | Downloads |
| `EventService` | Events |
| `EventMetricService` | Event metrics |
| `EventSubscriptionService` | Event subscriptions |
| `FeedService` | Feeds |
| `FileService` | Files |
| `JobService` | Jobs |
| `LayoutService` | Layouts |
| `MediaService` | Media |
| `NotificationService` | Notifications |
| `PTZService` | Pan-Tilt-Zoom |
| `UserService` | Users |

## EEN API Conventions

- **Timestamps** must use `+00:00` format (not `Z`). Use `formatTimestamp()`.
- **Actor parameters** use `camera:{cameraId}` format for event queries.
- **Include parameters** are comma-separated field names (e.g., `["deviceInfo", "status"]`).
- **Filter suffixes**: `__in`, `__gte`, `__lte`, `__ne`, `__contains`, `__any`.
- **Pagination**: The API returns `""` (empty string) for `nextPageToken`/`prevPageToken` when no more pages, not `null`. `PaginatedResult` normalizes this to `nil`, so use `if let nextPageToken = result.nextPageToken` to check for more pages.
- **Camera/Bridge status** can be a string or object — handled by `CameraStatusValue`/`BridgeStatusValue` custom decoders.
- **httpsBaseUrl** in token responses can be a string or `{hostname, port}` object — `TokenResponse` handles both.

## Example Apps

### swift-users

The `examples/swift-users/` directory contains a complete iOS demo app that demonstrates OAuth login, user profile display, and paginated user listing. It includes:

- WKWebView-based OAuth login flow
- Profile and Users tabs with SwiftUI
- XCUITest for automated UI verification
- Test credential injection for CI

```bash
# Run UI tests
cd examples/swift-users
./run-ui-tests.sh
```

### swift-media

The `examples/swift-media/` directory contains an iOS demo app showcasing the media features of the SDK:

- Live preview image with auto-refresh and timestamp display
- Recorded images (preview + main quality) with time picker and previous/next navigation
- HLS video playback via AVPlayer with progress slider and scrubbing
- Camera selection shared across all tabs via `@Binding`
- Shared time selector between Recorded Image and Recorded Video tabs
- "Image not available" fallback when recordings are missing
- App icon (blue media playback theme) displayed on login page
- Cloudflare proxy as default for iPhone builds
- 15 unit tests (formatDuration, formatEENTimestamp, AppConfig)
- 16 XCUITest E2E tests covering all tabs, sign out, and cross-tab persistence

```bash
# Run unit tests
xcodebuild test -project examples/swift-media/SwiftMedia.xcodeproj \
  -scheme SwiftMedia -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SwiftMediaTests

# Run E2E tests
cd examples/swift-media && ./run-ui-tests.sh
```

### ObservationCompanion

The `examples/ObservationCompanion/` directory contains an iOS app for real-time camera event monitoring. It supports two auth modes:

- **QR Code flow** — scan a deep link (`eenobserve://viewer?token=...&cam=...&base=...`) for token injection
- **OAuth flow** — full OAuth login via the mobile proxy

Features: live HLS video, SSE event streaming, event type filtering, token countdown, camera switching.

Unit tests cover EventTypeHash, CameraEvent, AppState URL parsing, state management, and token countdown logic:

```bash
# Run via Xcode (requires simulator)
xcodebuild test -project examples/ObservationCompanion/ObservationCompanion.xcodeproj \
  -scheme ObservationCompanion \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Testing

### Credentials Setup

Copy `.env.example` to `.env` and fill in your EEN test credentials:

```bash
cp .env.example .env
# Edit .env with your TEST_USER and TEST_PASSWORD
```

The token acquisition script (`scripts/get-test-token.js`) automates OAuth login using Playwright and writes `test-credentials.json`. It reads `TEST_USER`, `TEST_PASSWORD`, and optionally `CLIENT_ID` from `.env`.

### Run All Tests

```bash
./scripts/run-all-tests.sh
```

This discovers and runs all tests automatically:
- Toolkit unit tests (`swift test`)
- Toolkit integration tests (live API, requires proxy)
- All example app unit tests and E2E tests

Options:
```bash
SKIP_INTEGRATION=1 ./scripts/run-all-tests.sh   # skip live API tests
SKIP_E2E=1 ./scripts/run-all-tests.sh           # skip E2E/UI tests
```

### Individual Test Commands

Unit tests (SDK):
```bash
swift test
```

Integration tests (requires mobile proxy running at `127.0.0.1:3333`):
```bash
./scripts/run-integration-tests.sh
```

Example app E2E tests:
```bash
cd examples/swift-users && ./run-ui-tests.sh
cd examples/swift-media && ./run-ui-tests.sh
```

ObservationCompanion unit tests:
```bash
xcodebuild test -project examples/ObservationCompanion/ObservationCompanion.xcodeproj \
  -scheme ObservationCompanion \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Claude Code Agents

This project includes specialized [Claude Code agents](https://docs.anthropic.com/en/docs/claude-code/agents) in `.claude/agents/` that provide domain-specific expertise when working with the SDK. When you use Claude Code in this repository, these agents are automatically available and will be invoked when your task matches their domain.

### Available Agents

| Agent | Color | Trigger | What It Knows |
|-------|-------|---------|---------------|
| **een-auth-agent** | Blue | OAuth flows, login/logout, token management, session restore, SwiftUI auth state | `AuthManager`, `AuthState`, `OAuthWebSession`, `TokenStorage`, Keychain patterns |
| **een-devices-agent** | Orange | Cameras, bridges, device listing, status filtering, include parameters, device selection UI | `CameraService`, `BridgeService`, `Camera`/`Bridge` models, `CameraStatusValue` decoding |
| **een-events-agent** | Purple | Events, alerts, event types, event metrics, SSE streaming, event thumbnails | `EventService`, `EventMetricService`, `EventSubscriptionService`, `SSEClient`, include schemas |
| **een-media-agent** | Red | Live/recorded images, media intervals, feeds, stream URLs, HLS | `MediaService`, `FeedService`, image display, timestamp navigation, feed URL includes |
| **een-swifttest-agent** | Orange | E2E tests (XCUITest), credential injection, accessibility identifiers, simulator management | XCUITest patterns, file-based credentials, run scripts, accessibility rules |
| **test-runner** | Green | Running unit and integration tests, reporting results | `swift test`, `run-integration-tests.sh`, test filtering, result interpretation |

### How the Agents Work

When you ask Claude Code a question or request a task, it automatically selects the appropriate agent based on context. For example:

- *"How do I show live camera images?"* → **een-media-agent** is invoked with full knowledge of `MediaService`, `GetLiveImageParams`, and SwiftUI image display patterns.
- *"Query motion events for the last hour"* → **een-events-agent** knows the correct `actor` format (`camera:{id}`), timestamp functions, and include parameters for event thumbnails.
- *"Add OAuth login to my app"* → **een-auth-agent** guides the full flow: `getAuthUrl()` → WKWebView/ASWebAuthenticationSession → `handleCallback()` → session restore.
- *"Run the tests"* → **test-runner** executes the test suite and provides a structured report.

Each agent has access to the relevant source files, correct API endpoint paths, and working code examples. They enforce critical rules like always using `formatTimestamp()` (never ISO 8601 `Z` format) and the `camera:{id}` actor prefix for events.

### Using Agents Explicitly

You can also reference agents directly in your prompts:

```
Use the een-events-agent to help me implement real-time event streaming with SSE.
```

```
Use the een-devices-agent to show me how to filter cameras by status and tags.
```

### Agent File Structure

```
.claude/agents/
├── een-auth-agent.md      # OAuth, tokens, session management
├── een-devices-agent.md   # Cameras and bridges
├── een-events-agent.md    # Events, alerts, SSE streaming
├── een-media-agent.md     # Live/recorded images, feeds
├── een-swifttest-agent.md # E2E tests, XCUITest, credential injection
└── test-runner.md         # Test execution and reporting
```

Each agent file contains:
- **Frontmatter** — name, description, model, color (used by Claude Code UI)
- **Examples** — trigger patterns showing when the agent activates
- **Context Files** — source files the agent reads for accurate guidance
- **Key Types** — Swift struct/enum definitions for the domain
- **Code Patterns** — working snippets for common tasks
- **Constraints** — critical rules and gotchas (pagination, timestamp format, etc.)

## Documentation

Detailed guides are available in `docs/`:

- [Getting Started](docs/getting-started.md) — setup, authentication, first API call
- [Authentication](docs/authentication.md) — OAuth proxy flow, session restore, logout
- [API Reference](docs/api-reference.md) — all 16 services with parameters
- [Events](docs/events.md) — querying, types, includes, SSE streaming
- [Media](docs/media.md) — live/recorded images, feeds, HLS

## File Structure

```
Sources/EENApiToolkit/
  EENApiToolkit.swift          # Main entry point
  Auth/                        # OAuth, tokens, storage
  Configuration/               # EENToolkitConfig
  Core/                        # HTTPClient, errors, pagination, query encoding, timestamps
  Models/                      # 16 data model files
  Services/                    # 16 API service files
  SSE/                         # Server-Sent Events streaming
Tests/EENApiToolkitTests/
  Core/                        # Unit tests for core utilities
  Services/                    # Model decoding tests
  Integration/                 # Live API tests (require credentials)
  Mocks/                       # MockURLProtocol
examples/
  swift-users/                 # iOS demo app (SwiftUI, OAuth login, user listing)
  swift-media/                 # iOS media demo (live/recorded images, HLS video)
  ObservationCompanion/        # iOS camera event monitor (QR code + OAuth, live video, SSE)
docs/                          # Developer guides
.claude/agents/                # Claude Code specialized agents
```

## License

Private — All rights reserved.
