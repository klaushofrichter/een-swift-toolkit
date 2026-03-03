# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Native Swift SDK for the Eagle Eye Networks (EEN) Video API v3.0. iOS/macOS apps use this to integrate with the EEN cloud video platform.

- **Swift 5.9+ / swift-tools-version 5.9** — iOS 16+, macOS 13+
- **SPM distribution**, no external dependencies (pure Foundation/URLSession)
- All 16 EEN API resource domains implemented

## Build & Test

```bash
# Build
cd EENApiToolkit && swift build

# Run all unit tests
swift test

# Run a single test class
swift test --filter CameraModelTests

# Run a single test method
swift test --filter CameraModelTests/testDecodeCameraWithDeviceInfo

# Run integration tests (requires running OAuth proxy + credentials in .env)
./scripts/run-integration-tests.sh
```

No linter configured. No SwiftLint or SwiftFormat.

## Architecture

`EENToolkit` (final class, Sendable) is the central entry point with 16 service properties:

```
toolkit.cameras, .bridges, .events, .media, .feeds, .users, .auth, .authState, ...
```

### Concurrency Model
- **`HTTPClient`** — actor wrapping URLSession (all API calls route through this)
- **`AuthManager`** — actor handling OAuth proxy flow (login, refresh, revoke)
- **`AuthState`** — @MainActor ObservableObject for SwiftUI binding
- **Services** — Sendable structs (stateless, thread-safe)
- All API methods use `async throws` (not Result<T>)
- All models are `Codable + Sendable + Identifiable`

### Source Layout

```
Sources/EENApiToolkit/
  EENApiToolkit.swift          # Main entry point + EENToolkit class
  Auth/                        # OAuth, tokens, TokenStorage (Keychain/InMemory)
  Configuration/               # EENToolkitConfig
  Core/                        # HTTPClient, EENError, QueryParamEncoding, PaginatedResult, Timestamp
  Models/                      # 16 data model files (Camera, Bridge, Event, Media, etc.)
  Services/                    # 16 API service files (CameraService, EventService, etc.)
  SSE/                         # Server-Sent Events streaming (URLSessionDataDelegate)
Tests/EENApiToolkitTests/
  Core/                        # Unit tests for utilities
  Services/                    # Model decoding tests
  Auth/                        # Token storage tests
  Integration/                 # Live API tests (need proxy + credentials)
  Mocks/                       # MockURLProtocol
```

## Authentication Flow

Uses an OAuth proxy (not direct OAuth). The proxy holds refresh tokens server-side:

1. `toolkit.auth.getAuthUrl()` → EEN login URL
2. User authenticates via ASWebAuthenticationSession
3. `toolkit.auth.handleCallback(code:state:)` → exchanges code for token via proxy
4. Auto-refresh at 50% TTL or 5 min before expiry
5. `toolkit.auth.revokeToken()` → ends session

## EEN API Conventions

- **Timestamps:** Must use `+00:00` format (not `Z`). Use `formatTimestamp()`.
- **Actor parameters:** `camera:{cameraId}` format for events.
- **Include parameters:** Comma-separated field names (e.g., `["deviceInfo", "status"]`).
- **Filter suffixes:** `__in`, `__gte`, `__lte`, `__ne`, `__contains`, `__any` — handled by `QueryItemBuilder`.
- **Status decoding:** Camera/Bridge status can be string or object — `CameraStatusValue`/`BridgeStatusValue` use custom enum decoders.
- **Event data:** Polymorphic JSON via `DynamicCodingKey` + `AnyCodable`.
- **Pagination:** API returns `""` for `nextPageToken` when done (not `null`). `PaginatedResult` normalizes to `nil`. Check `nextPageToken != nil`.

## Build Gotchas

- **No regex literals** — `/pattern/` doesn't work with swift-tools-version 5.9. Use `NSRegularExpression`.
- **Logger.debug** — Uses string interpolation that captures closures. Use plain String params, not `@autoclosure`.
- **Actor isolation** — Task closures need `await self.method()` for actor-isolated methods.

## Specialized Agents

Agent files in `.claude/agents/` provide domain-specific guidance:
- `een-auth-agent.md` — OAuth flow, token management, SwiftUI integration
- `een-devices-agent.md` — Cameras and bridges
- `een-events-agent.md` — Events, alerts, SSE streaming, event types
- `een-media-agent.md` — Live/recorded images, feeds, media intervals
- `test-runner.md` — Test execution and reporting
