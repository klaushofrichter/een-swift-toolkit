# EENApiToolkit - Swift SDK for Eagle Eye Networks

## Project Overview

Native Swift SDK for the Eagle Eye Networks (EEN) Video API v3.0. Designed for iOS and macOS apps that integrate with the EEN cloud video platform.

- **Language:** Swift 5.9+
- **Platforms:** iOS 16+, macOS 13+
- **Distribution:** Swift Package Manager (SPM)
- **Dependencies:** None (pure Foundation/URLSession)

## Architecture

Central `EENToolkit` class exposes 16 service properties:

```swift
let toolkit = EENToolkit(config: config)
toolkit.cameras     // CameraService
toolkit.bridges     // BridgeService
toolkit.events      // EventService
toolkit.media       // MediaService
toolkit.feeds       // FeedService
toolkit.users       // UserService
toolkit.auth        // AuthManager (actor)
toolkit.authState   // AuthState (ObservableObject)
// ... and 8 more services
```

### Key Patterns
- All API methods use `async throws` (not Result<T>)
- All models are `Codable + Sendable + Identifiable`
- `HTTPClient` is an actor wrapping `URLSession` for thread safety
- `AuthManager` is an actor handling OAuth proxy flow
- `AuthState` is `@MainActor ObservableObject` for SwiftUI binding
- `QueryItemBuilder` handles EEN filter conventions (`__in`, `__gte`, `__lte`, `__ne`, `__contains`, `__any`)
- `PaginatedResult<T>` wraps paginated API responses with `nextPageToken`

### Concurrency Model
- `HTTPClient` — actor (thread-safe networking)
- `AuthManager` — actor (token lifecycle)
- `AuthState` — @MainActor (UI binding)
- Services — Sendable structs (stateless, safe to share)

## File Structure

```
Sources/EENApiToolkit/
  EENApiToolkit.swift          # Main entry point
  Auth/                        # OAuth, tokens, storage
  Configuration/               # EENToolkitConfig
  Core/                        # HTTPClient, errors, pagination, query encoding, timestamps
  Models/                      # 16 data model files (Camera, Bridge, Event, Media, etc.)
  Services/                    # 16 API service files
  SSE/                         # Server-Sent Events streaming
Tests/EENApiToolkitTests/
  Core/                        # Unit tests for core utilities
  Services/                    # Model decoding tests
  Integration/                 # Live API tests (require credentials)
  Mocks/                       # MockURLProtocol
```

## Authentication

Uses an OAuth proxy (not direct OAuth). The proxy handles refresh tokens server-side:

1. `toolkit.auth.getAuthUrl()` — returns EEN login URL
2. User authenticates in browser (ASWebAuthenticationSession)
3. `toolkit.auth.handleCallback(code:state:)` — exchanges code for token via proxy
4. Token auto-refreshes before expiry
5. `toolkit.auth.revokeToken()` — ends session

## Build & Test

```bash
# Build
swift build

# Run unit tests
swift test

# Run integration tests (requires proxy + credentials)
./scripts/run-integration-tests.sh
```

## EEN API Conventions

- Timestamps must use `+00:00` format (not `Z`). Use `formatTimestamp()`.
- Actor parameters use `camera:{cameraId}` format for events.
- Include parameters are comma-separated field names (e.g., `["deviceInfo", "status"]`).
- Filter suffixes: `__in`, `__gte`, `__lte`, `__ne`, `__contains`, `__any`.
- Camera/Bridge status can be string or object — handled by `CameraStatusValue`/`BridgeStatusValue` custom decoders.
- **Pagination:** The API returns `""` (empty string) for `nextPageToken`/`prevPageToken` when no more pages exist, not `null`. `PaginatedResult` normalizes empty strings to `nil` so callers can use simple `if let` / `!= nil` checks. Always check `nextPageToken != nil` (not `nextPageToken?.isEmpty`) to decide whether more pages exist.

## Specialized Agents

Agent files in `.claude/agents/` provide domain-specific guidance:
- `een-devices-agent.md` — Cameras and bridges
- `een-events-agent.md` — Events, alerts, event types
- `een-media-agent.md` — Live/recorded images, feeds, media intervals
- `een-auth-agent.md` — OAuth flow, token management, SwiftUI integration
- `test-runner.md` — Test execution and reporting
