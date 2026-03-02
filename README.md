# EEN Swift Toolkit

A native Swift SDK for the [Eagle Eye Networks](https://www.een.com) REST API. Provides type-safe access to all 16 API resource domains with full async/await support.

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
    proxyBaseUrl: "https://your-proxy.example.com",
    clientId: "YOUR_CLIENT_ID"
)
let toolkit = EENToolkit(config: config)

// Authenticate via OAuth proxy
let authUrl = try await toolkit.auth.getAuthUrl()
// ... handle OAuth flow ...

// Fetch cameras
let cameras = try await toolkit.cameras.list()
for camera in cameras.results {
    print(camera.name)
}
```

## Architecture

| Component | Role |
|-----------|------|
| `EENToolkit` | Central entry point with service properties (`toolkit.cameras`, `toolkit.events`, etc.) |
| `HTTPClient` | Actor wrapping URLSession for thread-safe networking |
| `AuthManager` | OAuth proxy flow (getAuthUrl, handleCallback, refreshToken, revokeToken) |
| `AuthState` | ObservableObject for SwiftUI integration |
| `TokenStorage` | Protocol with Keychain and InMemory implementations |
| `SSEClient` | Server-Sent Events via URLSessionDataDelegate |

## API Services

All services use `async throws` and return Codable, Sendable, Identifiable models.

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

## Query Filters

The SDK supports EEN filter conventions via `QueryItemBuilder`:

```swift
let events = try await toolkit.events.list(
    startTimestamp: .gte("2024-01-01T00:00:00.000Z"),
    actorType: .in(["camera"]),
    type: .contains("motion")
)
```

Supported operators: `__in`, `__gte`, `__lte`, `__ne`, `__contains`, `__any`.

## Testing

Unit tests:
```bash
swift test
```

Integration tests require a running OAuth proxy and test credentials:
```bash
./scripts/run-integration-tests.sh
```

## License

Private — All rights reserved.
