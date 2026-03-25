#if canImport(ActivityKit)
import ActivityKit
import Foundation

@MainActor
class LiveActivityManager {
    private var currentActivity: Activity<MonitoringActivityAttributes>?

    func startMonitoring(cameraName: String) {
        endMonitoring()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }

        let attributes = MonitoringActivityAttributes()
        let initialState = MonitoringActivityAttributes.ContentState(
            cameraName: cameraName,
            latestEventEmoji: "📡",
            latestEventDescription: "Connecting to event stream...",
            eventCount: 0,
            lastEventTimestamp: nil,
            latestEventId: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("[LiveActivity] Started: \(activity.id)")
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }

    func updateWithEvent(cameraName: String, emoji: String, description: String, eventCount: Int, timestamp: Date? = nil, eventId: String? = nil) {
        guard let activity = currentActivity else { return }

        let updatedState = MonitoringActivityAttributes.ContentState(
            cameraName: cameraName,
            latestEventEmoji: emoji,
            latestEventDescription: description,
            eventCount: eventCount,
            lastEventTimestamp: timestamp,
            latestEventId: eventId
        )

        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }

    func endMonitoring() {
        guard let activity = currentActivity else { return }

        let finalState = MonitoringActivityAttributes.ContentState(
            cameraName: "",
            latestEventEmoji: "⏹️",
            latestEventDescription: "Monitoring ended",
            eventCount: 0,
            lastEventTimestamp: nil,
            latestEventId: nil
        )

        Task {
            await activity.end(.init(state: finalState, staleDate: nil),
                              dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
#endif
