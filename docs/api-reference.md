# API Reference

EENSwiftToolkit provides 16 service properties on the central `EENToolkit` class. All methods use `async throws`.

## Services Overview

| Service | Property | Description |
|---|---|---|
| CameraService | `toolkit.cameras` | List, get, and filter cameras |
| BridgeService | `toolkit.bridges` | List, get, and filter bridges |
| EventService | `toolkit.events` | Query events, event types, field values |
| EventMetricService | `toolkit.eventMetrics` | Event metrics and aggregations |
| EventSubscriptionService | `toolkit.eventSubscriptions` | SSE event subscriptions |
| MediaService | `toolkit.media` | Live/recorded images, media intervals |
| FeedService | `toolkit.feeds` | Camera feed URLs (HLS, RTSP, etc.) |
| UserService | `toolkit.users` | Current user info |
| LayoutService | `toolkit.layouts` | Camera layouts |
| AlertService | `toolkit.alerts` | Alert rules |
| AutomationService | `toolkit.automations` | Automation workflows |
| NotificationService | `toolkit.notifications` | Notification settings |
| PTZService | `toolkit.ptz` | Pan-tilt-zoom control |
| DownloadService | `toolkit.downloads` | Video/image downloads |
| FileService | `toolkit.files` | File management |
| JobService | `toolkit.jobs` | Async job management |

## Cameras

### List Cameras

```swift
var params = ListCamerasParams(pageSize: 20)
params.include = ["deviceInfo", "status"]
params.statusIn = [.online, .streaming]  // Optional: filter by status
params.tagsContains = ["entrance"]       // Optional: filter by tags

let result = try await toolkit.cameras.list(params: params)
// result.results: [Camera]
// result.nextPageToken: String?
```

### Get a Single Camera

```swift
let camera = try await toolkit.cameras.get(
    id: cameraId,
    include: ["deviceInfo", "status", "tags", "capabilities"]
)
```

### Camera Include Values

| Value | Returns |
|---|---|
| `deviceInfo` | Make, model, firmware, serial number |
| `status` | Connection status (online, offline, etc.) |
| `tags` | User-assigned tags |
| `devicePosition` | Latitude, longitude, floor |
| `shareDetails` | Sharing information |
| `capabilities` | Camera capabilities (PTZ, audio, etc.) |
| `networkInfo` | Network configuration |

### Camera Status

Camera status can be a string or an object. Always use `.effectiveStatus`:

```swift
if let status = camera.status?.effectiveStatus {
    switch status {
    case .online, .streaming: // Camera is available
    case .offline, .deviceOffline, .bridgeOffline: // Camera is down
    default: break
    }
}
```

## Bridges

### List Bridges

```swift
var params = ListBridgesParams()
params.include = ["deviceInfo", "status", "networkInfo"]

let result = try await toolkit.bridges.list(params: params)
```

### Get a Single Bridge

```swift
let bridge = try await toolkit.bridges.get(
    id: bridgeId,
    include: ["deviceInfo", "status"]
)
```

## Events

### Query Events

```swift
let oneHourAgo = formatTimestamp(Date().addingTimeInterval(-3600))
let now = formatTimestamp(Date())

var params = ListEventsParams(
    actor: "camera:\(cameraId)",              // Required: camera:{id} format
    typeIn: ["een.motionDetectionEvent.v1"],   // Event type filter
    startTimestampGte: oneHourAgo,             // Required: start time
    pageSize: 50
)
params.endTimestampLte = now                   // Required: end time

let result = try await toolkit.events.list(params: params)
```

### Discover Available Event Types

```swift
// Event types for a specific camera
let fieldValues = try await toolkit.events.listFieldValues(
    actor: "camera:\(cameraId)"
)
// fieldValues.type: ["een.motionDetectionEvent.v1", ...]

// All event types globally
let allTypes = try await toolkit.events.listTypes(
    params: ListEventTypesParams(pageSize: 100)
)
```

### Include Event Data

```swift
var params = ListEventsParams(...)
params.include = ["data.een.fullFrameImageUrl.v1"]

let result = try await toolkit.events.list(params: params)
for event in result.results {
    for dataItem in event.data {
        if dataItem.type == "een.fullFrameImageUrl.v1",
           let urlValue = dataItem.additionalProperties?["httpsUrl"],
           case .string(let imageUrl) = urlValue {
            // imageUrl is the event thumbnail URL
        }
    }
}
```

### Common Event Include Values

| Include Value | Description |
|---|---|
| `data.een.fullFrameImageUrl.v1` | Full-frame event thumbnail URL |
| `data.een.boundingBoxSvg.v1` | SVG bounding box overlay |
| `data.een.objectDetectionData.v1` | Object detection metadata |

## Media

### Live Image

```swift
let params = GetLiveImageParams(deviceId: cameraId, type: "preview")
let result = try await toolkit.media.getLiveImage(params: params)
// result.imageData: Data (JPEG bytes)
```

### Recorded Image

```swift
var params = GetRecordedImageParams()
params.type = .preview
params.timestampGte = formatTimestamp(Date().addingTimeInterval(-3600))

let result = try await toolkit.media.getRecordedImage(
    deviceId: cameraId, params: params
)
// result.imageData: Data (JPEG bytes)
// result.nextToken / result.prevToken for navigation
```

### Media Intervals

Query which time ranges have recordings:

```swift
let params = ListMediaParams(
    deviceId: cameraId,
    type: .preview,
    mediaType: .video,
    startTimestamp: formatTimestamp(Date().addingTimeInterval(-3600))
)
let result = try await toolkit.media.listMedia(params: params)
for interval in result.results {
    print("\(interval.startTimestamp) - \(interval.endTimestamp)")
}
```

## Feeds

Get streaming URLs for a camera:

```swift
var params = ListFeedsParams()
params.deviceId = cameraId
params.include = ["hlsUrl", "multipartUrl", "flvUrl", "rtspUrl"]

let result = try await toolkit.feeds.list(params: params)
for feed in result.results {
    print("Feed: \(feed.type.rawValue) — HLS: \(feed.hlsUrl ?? "none")")
}
```

## Users

```swift
let user = try await toolkit.users.getCurrentUser()
print("Logged in as: \(user.email)")
```

## Pagination

All list methods return `PaginatedResult<T>`:

```swift
var allCameras: [Camera] = []
var pageToken: String? = nil

repeat {
    var params = ListCamerasParams(pageSize: 100)
    params.pageToken = pageToken
    let result = try await toolkit.cameras.list(params: params)
    allCameras.append(contentsOf: result.results)
    pageToken = result.nextPageToken
} while pageToken != nil
```

> **Note:** The EEN API returns `""` (empty string) — not `null` — for `nextPageToken` when there are no more pages. `PaginatedResult` automatically normalizes empty strings to `nil`, so you can safely use `while pageToken != nil` or `if let` checks. You do not need to check for empty strings yourself.

## Timestamps

All EEN API timestamps must use `+00:00` format (not `Z`). Always use the helper:

```swift
let timestamp = formatTimestamp(Date())
// Produces: "2024-01-15T10:30:00.000+00:00"
```

## Error Handling

All methods throw `EENError`:

```swift
do {
    let cameras = try await toolkit.cameras.list(params: params)
} catch let error as EENError {
    switch error.code {
    case .unauthorized:
        // Token expired or invalid — re-authenticate
    case .notFound:
        // Resource not found
    case .networkError:
        // Network connectivity issue
    default:
        print("API error: \(error.message)")
    }
}
```
