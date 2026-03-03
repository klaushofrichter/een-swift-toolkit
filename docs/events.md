# Working with Events

Query camera events, discover event types, include event data, and receive real-time event notifications via SSE.

## Event Query Basics

Every event query requires:
1. An `actor` in `camera:{cameraId}` format
2. A start timestamp (`startTimestampGte`)
3. An end timestamp (`endTimestampLte` or `startTimestampLte`)

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
```

## Discovering Event Types

Different cameras support different event types. Discover what's available:

```swift
// Event types for a specific camera
let fieldValues = try await toolkit.events.listFieldValues(
    actor: "camera:\(cameraId)"
)
for type in fieldValues.type {
    print(type)  // e.g. "een.motionDetectionEvent.v1"
}
```

Common event types:
| Type | Description |
|---|---|
| `een.motionDetectionEvent.v1` | Motion detected |
| `een.tamperDetectionEvent.v1` | Camera tamper detected |
| `een.lineCounterEvent.v1` | Line crossing counter |
| `een.loiteringDetectionEvent.v1` | Loitering detected |
| `een.intrusionDetectionEvent.v1` | Intrusion detected |

## Querying Multiple Event Types

```swift
var params = ListEventsParams(
    actor: "camera:\(cameraId)",
    typeIn: [
        "een.motionDetectionEvent.v1",
        "een.tamperDetectionEvent.v1"
    ],
    startTimestampGte: oneHourAgo
)
params.endTimestampLte = now
```

## Including Event Data

Events can carry additional data like image URLs and bounding boxes. Request them with the `include` parameter:

### Event Thumbnail Images

```swift
var params = ListEventsParams(
    actor: "camera:\(cameraId)",
    typeIn: ["een.motionDetectionEvent.v1"],
    startTimestampGte: oneHourAgo
)
params.endTimestampLte = now
params.include = ["data.een.fullFrameImageUrl.v1"]

let result = try await toolkit.events.list(params: params)

for event in result.results {
    for dataItem in event.data {
        if dataItem.type == "een.fullFrameImageUrl.v1",
           let urlValue = dataItem.additionalProperties?["httpsUrl"],
           case .string(let imageUrl) = urlValue {
            // Load imageUrl with AsyncImage or URLSession
        }
    }
}
```

### Bounding Box Overlay

```swift
params.include = ["data.een.boundingBoxSvg.v1"]

// Access SVG data
if dataItem.type == "een.boundingBoxSvg.v1",
   let svgValue = dataItem.additionalProperties?["svgData"],
   case .string(let svgString) = svgValue {
    // Overlay svgString on the camera image
}
```

### Multiple Include Values

```swift
params.include = [
    "data.een.fullFrameImageUrl.v1",
    "data.een.boundingBoxSvg.v1",
    "data.een.objectDetectionData.v1"
]
```

## Get a Single Event

```swift
// Without extra data
let event = try await toolkit.events.get(id: eventId)

// With include data
let event = try await toolkit.events.get(
    id: eventId,
    include: ["data.een.fullFrameImageUrl.v1"]
)
```

## Event Metrics

Get aggregated event counts in time buckets:

```swift
let metrics = try await toolkit.eventMetrics.getMetrics(
    actor: "camera:\(cameraId)",
    typeIn: ["een.motionDetectionEvent.v1"],
    startTimestampGte: formatTimestamp(oneDayAgo),
    granularity: "PT1H"   // 1-hour buckets
)
```

## Real-Time Events (SSE)

Receive events as they happen via Server-Sent Events:

```swift
// 1. Create a subscription
let subscription = try await toolkit.eventSubscriptions.create(...)

// 2. Connect to the SSE stream
let connection = try await toolkit.eventSubscriptions.connect(id: subscription.id)

// 3. Consume events as they arrive
for await event in connection.events {
    print("Event: \(event.type) at \(event.startTimestamp)")
}
```

Event subscriptions have a 15-minute TTL (server-determined, read-only).

## SwiftUI Event List Example

```swift
@MainActor
class EventListViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false

    let toolkit: EENToolkit

    init(toolkit: EENToolkit) {
        self.toolkit = toolkit
    }

    func loadEvents(cameraId: String) async {
        isLoading = true
        defer { isLoading = false }

        let oneHourAgo = formatTimestamp(Date().addingTimeInterval(-3600))
        let now = formatTimestamp(Date())

        var params = ListEventsParams(
            actor: "camera:\(cameraId)",
            typeIn: ["een.motionDetectionEvent.v1"],
            startTimestampGte: oneHourAgo,
            pageSize: 50
        )
        params.endTimestampLte = now
        params.include = ["data.een.fullFrameImageUrl.v1"]

        do {
            let result = try await toolkit.events.list(params: params)
            events = result.results
        } catch {
            print("Failed to load events: \(error)")
        }
    }
}

struct EventListView: View {
    @StateObject private var viewModel: EventListViewModel
    let cameraId: String

    init(toolkit: EENToolkit, cameraId: String) {
        _viewModel = StateObject(wrappedValue: EventListViewModel(toolkit: toolkit))
        self.cameraId = cameraId
    }

    var body: some View {
        List(viewModel.events) { event in
            VStack(alignment: .leading) {
                Text(event.type)
                    .font(.headline)
                Text(event.startTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await viewModel.loadEvents(cameraId: cameraId)
        }
    }
}
```

## Timestamps

All event timestamps must use `+00:00` format. Always use `formatTimestamp()`:

```swift
let timestamp = formatTimestamp(Date())
// "2024-01-15T10:30:00.000+00:00" (NOT "Z" format)
```

The EEN API will reject timestamps that use `Z` suffix.
