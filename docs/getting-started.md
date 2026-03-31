# Getting Started with EENSwiftToolkit for Swift

Build iOS and macOS apps that integrate with the Eagle Eye Networks cloud video platform using this native Swift SDK.

## Requirements

- Swift 5.9+
- iOS 16+ / macOS 13+
- An Eagle Eye Networks account
- An OAuth proxy server (handles refresh tokens server-side)

## Installation

Add EENSwiftToolkit to your Xcode project via Swift Package Manager:

**File > Add Package Dependencies** and enter the package URL, or add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://your-repo/EENSwiftToolkit", from: "1.0.0")
]
```

Then add to your target:

```swift
.target(name: "YourApp", dependencies: ["EENSwiftToolkit"])
```

## Quick Start

### 1. Configure the Toolkit

```swift
import EENSwiftToolkit

let config = EENToolkitConfig(
    proxyUrl: "https://your-proxy.workers.dev",
    clientId: "YOUR-CLIENT-ID",
    redirectUri: "yourapp://callback",
    storageStrategy: .keychain
)

let toolkit = EENToolkit(config: config)
```

### 2. Authenticate

```swift
// Open the EEN login page in a system browser sheet
try await toolkit.webSession.authenticate()
// On success, toolkit.authState.isAuthenticated becomes true
```

### 3. List Cameras

```swift
var params = ListCamerasParams(pageSize: 20)
params.include = ["deviceInfo", "status"]
let result = try await toolkit.cameras.list(params: params)

for camera in result.results {
    print("\(camera.name) — \(camera.status?.effectiveStatus ?? .offline)")
}
```

### 4. Get a Live Image

```swift
let params = GetLiveImageParams(deviceId: cameraId, type: "preview")
let result = try await toolkit.media.getLiveImage(params: params)

// Display in SwiftUI
if let uiImage = UIImage(data: result.imageData) {
    Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
}
```

### 5. Query Events

```swift
let oneHourAgo = formatTimestamp(Date().addingTimeInterval(-3600))
let now = formatTimestamp(Date())

var params = ListEventsParams(
    actor: "camera:\(cameraId)",
    typeIn: ["een.motionDetectionEvent.v1"],
    startTimestampGte: oneHourAgo,
    pageSize: 50
)
params.endTimestampLte = now

let result = try await toolkit.events.list(params: params)
print("Found \(result.results.count) motion events")
```

## SwiftUI Integration

EENSwiftToolkit is designed for SwiftUI. The `AuthState` class is an `ObservableObject` that drives your UI:

```swift
@main
struct MyApp: App {
    let toolkit: EENToolkit

    init() {
        let config = EENToolkitConfig(
            proxyUrl: "https://your-proxy.workers.dev",
            clientId: "YOUR-CLIENT-ID",
            redirectUri: "yourapp://callback",
            storageStrategy: .keychain
        )
        toolkit = EENToolkit(config: config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(toolkit: toolkit)
                .environmentObject(toolkit.authState)
                .task {
                    let _ = await toolkit.restoreSession()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    let toolkit: EENToolkit

    var body: some View {
        if authState.isAuthenticated {
            CameraListView(toolkit: toolkit)
        } else {
            LoginView(toolkit: toolkit)
        }
    }
}
```

## Next Steps

- [API Reference](api-reference.md) — Full reference for all 16 services
- [Authentication Guide](authentication.md) — OAuth flow, session restoration, and token lifecycle
- [Working with Events](events.md) — Event queries, include parameters, and SSE streaming
- [Media and Images](media.md) — Live/recorded images, feeds, and media intervals
