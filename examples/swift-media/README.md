# SwiftMedia

A SwiftUI iOS app demonstrating live and recorded media features of the [EENApiToolkit](../../README.md) — the native Swift SDK for Eagle Eye Networks REST API v3.0.

## Features

- **OAuth Login** — Sign in via the EEN OAuth proxy
- **Camera Selection** — Shared camera picker across all tabs
- **Live Image** — Auto-refreshing live preview image (5-second interval)
- **Recorded Image** — Time-based retrieval of preview and main (full resolution) images with previous/next navigation
- **Recorded Video** — HLS video playback via AVPlayer with time selection

## Requirements

- iOS 16+
- Xcode 15+
- Running OAuth proxy (`http://127.0.0.1:3333` or Cloudflare Workers)

## Running

1. Start the OAuth proxy:
   ```bash
   cd ../een-mobile-proxy/proxy && npm run dev
   ```

2. Open `SwiftMedia.xcodeproj` in Xcode and run on a simulator, or build from the command line:
   ```bash
   xcodebuild -project SwiftMedia.xcodeproj -scheme SwiftMedia \
       -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

3. Sign in with your EEN credentials.

## Architecture

| File | Purpose |
|------|---------|
| `SwiftMediaApp.swift` | Entry point, credential injection for testing |
| `ContentView.swift` | Auth gate (login vs main UI) |
| `LoginView.swift` | OAuth sign-in screen |
| `OAuthWebView.swift` | WKWebView OAuth redirect capture |
| `MainTabView.swift` | Tab bar with Live, Recorded, Video tabs |
| `CameraPickerView.swift` | Shared camera selection component |
| `LiveImageView.swift` | Live preview image with auto-refresh |
| `RecordedImageView.swift` | Recorded images (preview + main) with time picker |
| `RecordedVideoView.swift` | HLS video playback with AVPlayer |
| `Config.swift` | Proxy URL and client configuration |

## EEN API Usage

| Feature | API Endpoint | Toolkit Method |
|---------|-------------|----------------|
| Live image | `GET /media/liveImage.jpeg` | `toolkit.media.getLiveImage(params:)` |
| Recorded image | `GET /media/recordedImage.jpeg` | `toolkit.media.getRecordedImage(deviceId:params:)` |
| Media intervals | `GET /media` | `toolkit.media.listMedia(params:)` |
| HLS video | Feed `hlsUrl` via `GET /feeds` | `toolkit.feeds.list(params:)` |
| Media session | `POST /media/session` | `toolkit.media.initMediaSession(deviceId:)` |
| Camera list | `GET /cameras` | `toolkit.cameras.list(params:)` |

### HLS Video Playback

HLS streaming uses `AVURLAsset` with the `AVURLAssetHTTPHeaderFieldsKey` option to inject the Bearer token into all segment requests:

```swift
let headers = ["Authorization": "Bearer \(token)"]
let asset = AVURLAsset(url: hlsUrl, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
```

### Recorded Image Navigation

Response headers from image endpoints provide pagination tokens:
- `X-Een-Timestamp` — Timestamp of the returned image
- `X-Een-NextToken` — Token for the next image
- `X-Een-PrevToken` — Token for the previous image

## E2E Tests

XCUITests verify the app's UI and API integration:

```bash
# Run all UI tests (requires proxy + credentials)
./run-ui-tests.sh
```

Tests cover: login screen, tab navigation, camera picker, live image loading, and control visibility on all tabs.

## Configuration

| Environment Variable | Default | Purpose |
|---------------------|---------|---------|
| `PROXY_URL` | `http://127.0.0.1:3333` | OAuth proxy URL |
| `EEN_CLIENT_ID` | `PREVIEW-KLAUS-MOBILE` | EEN API client ID |
| `EEN_REDIRECT_URI` | `http://127.0.0.1:3333` | OAuth redirect URI |
