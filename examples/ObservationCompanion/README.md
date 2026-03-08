# Observation Companion

A SwiftUI iOS app for real-time camera event monitoring using the [EENApiToolkit](../../README.md) — the native Swift SDK for Eagle Eye Networks REST API v3.0.

![Live View](docs/screenshot-live.png)

## Features

- **Two auth modes:**
  - **QR Code flow** — scan a deep link (`eenobserve://view?token=...&cam=...&base=...`) from the [EEN Camera Observation App](https://klaushofrichter.github.io/een-observation-app)
  - **OAuth flow** — full OAuth login via the Cloudflare proxy
- **Live HLS video** — streaming via AVPlayer with "LIVE HD" badge
- **SSE event streaming** — real-time event feed via Server-Sent Events
- **Event history** — loads up to 250 recent events on connect (configurable duration)
- **Event detail view** — tap an event to see recorded image with bounding box overlay
- **Recorded video playback** — play recorded HLS video at event timestamp with timeline scrubber
- **Event navigation** — Older/Newer buttons with time deltas, swipe left/right gestures
- **Event type icons** — 56 EEN event types mapped to specific emoji icons, green border when bounding boxes present
- **Event type filtering** — toggle event types, shows hashed short codes
- **Camera switching** — switch between cameras on the same account
- **Landscape mode** — 50/50 split between live video and event feed
- **Token countdown** — visual countdown for QR code token expiry
- **Sound alerts** — optional audio notification on new events
- **Paste URL** — paste a deep link URL for simulator/testing use
- **Reload** — re-use the last QR code URL (if TTL still valid)
- **Version display** — toolkit version from `package.json` on landing page

## Requirements

- iOS 16+
- Xcode 15+
- OAuth proxy (Cloudflare Workers by default, or local `http://127.0.0.1:3333`)
- EEN account with at least one camera

## Running

### On Simulator

1. Build and run:
   ```bash
   xcodebuild -project ObservationCompanion.xcodeproj -scheme ObservationCompanion \
       -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   ```

2. Use "Paste URL" to enter a deep link, or tap "Sign In with Eagle Eye Networks" for OAuth.

### On iPhone

Open `ObservationCompanion.xcodeproj` in Xcode, select your iPhone, and run. The app defaults to the Cloudflare proxy for OAuth.

## Architecture

```
ObservationCompanion/
├── ObservationCompanionApp.swift  # Entry point, URL handling, token injection
├── Config.swift                   # Proxy URL, client ID, URL scheme
├── Version.swift                  # Auto-generated toolkit version
├── Models/
│   ├── AppState.swift             # Connection state, HLS player, SSE, token countdown
│   └── CameraEvent.swift          # Event model, bounding box extraction, 56 event type icons
├── Utils/
│   ├── EventTypeHash.swift        # 3-char hash codes for event types
│   └── SoundPlayer.swift          # Audio alert on new events
└── Views/
    ├── MainContentView.swift      # State-based navigation (scanner/connecting/live/expired/error)
    ├── ScannerView.swift          # QR scanner, paste URL, OAuth login, version display
    ├── OAuthWebView.swift         # WKWebView OAuth + warmup web view
    ├── LiveVideoView.swift        # HLS video player with LIVE HD badge
    ├── EventFeedView.swift        # Event list, detail view, recorded video, navigation
    └── TokenCountdownView.swift   # Token TTL progress bar
```

## EEN API Usage

| Feature | API Endpoint | Toolkit Method |
|---------|-------------|----------------|
| Camera info | `GET /cameras/{id}` | `toolkit.cameras.get(id:)` |
| Camera list | `GET /cameras` | `toolkit.cameras.list(params:)` |
| HLS feed URL | `GET /feeds` | `toolkit.feeds.list(params:)` |
| Media session | `POST /media/session` | `toolkit.media.initMediaSession(deviceId:)` |
| Event types per camera | `GET /events/fieldValues` | `toolkit.events.listFieldValues(actor:)` |
| Event history | `GET /events` | `toolkit.events.list(params:)` |
| SSE subscription | `POST /eventSubscriptions` | `toolkit.eventSubscriptions.create(params:)` |
| SSE stream | SSE connection | `toolkit.eventSubscriptions.connect(sseUrl:options:)` |
| Recorded image | `GET /media/recordedImage` | `toolkit.media.getRecordedImage(deviceId:params:)` |
| Recorded video | `GET /media` | `toolkit.media.listMedia(params:)` with `include: ["hlsUrl"]` |

## Tests

### Unit Tests (58 tests)

Cover EventTypeHash, CameraEvent, AppState URL parsing, state management, and token countdown:

```bash
xcodebuild test -project ObservationCompanion.xcodeproj \
  -scheme ObservationCompanion \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:ObservationCompanionTests
```

### E2E Tests (6 tests)

XCUITests verify app launch, live video connection, event feed, and camera switching against a live EEN account:

```bash
./run-e2e-tests.sh
```

## Configuration

| Environment Variable | Default | Purpose |
|---------------------|---------|---------|
| `EEN_PROXY_URL` | `https://een-mobile-proxy.klaushofrichter.workers.dev` | OAuth proxy URL |
| `EEN_CLIENT_ID` | `PREVIEW-KLAUS-MOBILE` | EEN API client ID |

### Token Injection (Testing)

For E2E tests or development, inject credentials via environment variables:

| Variable | Purpose |
|----------|---------|
| `EEN_TOKEN` | Access token |
| `EEN_BASE_URL` | API base URL |
| `EEN_CAMERA_ID` | Camera to connect to |
| `EEN_EVENT_HASHES` | Comma-separated event type hashes |
| `EEN_TTL` | Token TTL in seconds |

## Deep Link Format

```
eenobserve://view?token=<JWT>&cam=<cameraId>&base=<apiBaseUrl>&ttl=<epochSeconds>&events=<hashes>
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `token` | Yes | EEN access token (JWT) |
| `cam` | Yes | Camera ID |
| `base` | Yes | API base URL (URL-encoded) |
| `ttl` | No | Token expiry as Unix epoch |
| `events` | No | Comma-separated 3-char event type hashes |
