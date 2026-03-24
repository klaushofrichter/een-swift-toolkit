#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct MonitoringActivityAttributes: ActivityAttributes {
    /// Camera name (static for the lifetime of the activity)
    let cameraName: String
    /// Camera ID (static for the lifetime of the activity)
    let cameraId: String

    struct ContentState: Codable, Hashable {
        let latestEventEmoji: String
        let latestEventDescription: String
        let eventCount: Int
        let lastEventTimestamp: Date
    }
}
#endif
