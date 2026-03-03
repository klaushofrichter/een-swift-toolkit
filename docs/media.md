# Media and Images

Display live camera snapshots, retrieve recorded images, navigate footage by timestamp, query recording intervals, and get streaming URLs.

## Live Images

Get a live JPEG snapshot from a camera:

```swift
let params = GetLiveImageParams(deviceId: cameraId, type: "preview")
let result = try await toolkit.media.getLiveImage(params: params)

// result.imageData — Raw JPEG bytes
// result.contentType — "image/jpeg"
```

### Display in SwiftUI

```swift
if let uiImage = UIImage(data: result.imageData) {
    Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
}
```

### Auto-Refreshing Live Image

```swift
@MainActor
class LiveImageViewModel: ObservableObject {
    @Published var image: UIImage?
    private var refreshTask: Task<Void, Never>?

    func startRefreshing(toolkit: EENToolkit, cameraId: String) {
        refreshTask = Task {
            while !Task.isCancelled {
                do {
                    let result = try await toolkit.media.getLiveImage(
                        params: GetLiveImageParams(deviceId: cameraId)
                    )
                    image = UIImage(data: result.imageData)
                } catch {
                    print("Live image error: \(error)")
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 sec
            }
        }
    }

    func stop() { refreshTask?.cancel() }
}

struct LiveImageView: View {
    @StateObject private var viewModel = LiveImageViewModel()
    let toolkit: EENToolkit
    let cameraId: String

    var body: some View {
        Group {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear { viewModel.startRefreshing(toolkit: toolkit, cameraId: cameraId) }
        .onDisappear { viewModel.stop() }
    }
}
```

## Recorded Images

### By Timestamp

Retrieve a recorded image from a specific time:

```swift
var params = GetRecordedImageParams()
params.type = .preview  // or .main for full resolution
params.timestampGte = formatTimestamp(Date().addingTimeInterval(-3600))

let result = try await toolkit.media.getRecordedImage(
    deviceId: cameraId, params: params
)
// result.imageData — JPEG bytes
// result.nextToken — Token for next image
// result.prevToken — Token for previous image
```

### Stream Types

| Type | Description |
|---|---|
| `.preview` | Lower resolution, faster to load |
| `.main` | Full resolution |

### Navigating with Page Tokens

Move forward and backward through recorded footage:

```swift
// Get initial image
let first = try await toolkit.media.getRecordedImage(
    deviceId: cameraId, params: params
)

// Navigate forward
if let nextToken = first.nextToken {
    var nextParams = GetRecordedImageParams()
    nextParams.pageToken = nextToken
    let next = try await toolkit.media.getRecordedImage(
        deviceId: cameraId, params: nextParams
    )
}

// Navigate backward
if let prevToken = first.prevToken {
    var prevParams = GetRecordedImageParams()
    prevParams.pageToken = prevToken
    let prev = try await toolkit.media.getRecordedImage(
        deviceId: cameraId, params: prevParams
    )
}
```

## Media Intervals

Query which time ranges have recordings available:

```swift
let params = ListMediaParams(
    deviceId: cameraId,
    type: .preview,
    mediaType: .video,
    startTimestamp: formatTimestamp(Date().addingTimeInterval(-3600))
)
let result = try await toolkit.media.listMedia(params: params)

for interval in result.results {
    print("Recording: \(interval.startTimestamp) to \(interval.endTimestamp)")
}
```

## Feeds (Stream URLs)

Get streaming URLs for live and recorded video:

```swift
var params = ListFeedsParams()
params.deviceId = cameraId
params.include = ["hlsUrl", "multipartUrl", "flvUrl", "rtspUrl"]

let result = try await toolkit.feeds.list(params: params)

for feed in result.results {
    print("Type: \(feed.type.rawValue)")
    print("  HLS: \(feed.hlsUrl ?? "none")")
    print("  RTSP: \(feed.rtspUrl ?? "none")")
}
```

### Filter by Feed Type

```swift
var params = ListFeedsParams()
params.deviceId = cameraId
params.type = .preview  // Only preview feeds
params.include = ["hlsUrl", "multipartUrl"]
```

### Feed Types

| Type | Description |
|---|---|
| `.main` | Full resolution stream |
| `.preview` | Lower resolution preview stream |
| `.talkdown` | Audio talkdown channel |

### Playing HLS in SwiftUI

```swift
import AVKit

struct CameraPlayerView: View {
    let hlsUrl: String

    var body: some View {
        if let url = URL(string: hlsUrl) {
            VideoPlayer(player: AVPlayer(url: url))
        }
    }
}
```

## API Endpoints

| Method | Endpoint |
|---|---|
| Live image | `GET /api/v3.0/media/liveImage.jpeg?deviceId=...&type=preview` |
| Recorded image | `GET /api/v3.0/media/recordedImage.jpeg?deviceId=...` |
| List media intervals | `GET /api/v3.0/media?deviceId=...` |
| Media session | `POST /api/v3.0/media/session` |

## Important Notes

- Live and recorded image methods return raw `Data` (JPEG bytes), not base64
- Always use `formatTimestamp()` for timestamp parameters — the API rejects `Z` suffix
- Feed URLs require the corresponding `include` parameter to be populated
- Media session initialization may be required before using certain stream URLs
- The `listMedia` endpoint uses filter suffixes (`startTimestamp__gte`) internally
