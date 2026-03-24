#if canImport(ActivityKit)
import ActivityKit
import Foundation

@MainActor
class LiveActivityManager {
    private var currentActivity: Activity<MonitoringActivityAttributes>?

    func startMonitoring(cameraName: String, cameraId: String) {
        endMonitoring()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }

        let attributes = MonitoringActivityAttributes(
            cameraName: cameraName,
            cameraId: cameraId
        )
        let initialState = MonitoringActivityAttributes.ContentState(
            latestEventEmoji: "📡",
            latestEventDescription: "Connecting to event stream...",
            eventCount: 0,
            lastEventTimestamp: Date()
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

    func updateWithEvent(emoji: String, description: String, eventCount: Int) {
        guard let activity = currentActivity else { return }

        let updatedState = MonitoringActivityAttributes.ContentState(
            latestEventEmoji: emoji,
            latestEventDescription: description,
            eventCount: eventCount,
            lastEventTimestamp: Date()
        )

        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }

    func endMonitoring() {
        guard let activity = currentActivity else { return }

        let finalState = MonitoringActivityAttributes.ContentState(
            latestEventEmoji: "⏹️",
            latestEventDescription: "Monitoring ended",
            eventCount: 0,
            lastEventTimestamp: Date()
        )

        Task {
            await activity.end(.init(state: finalState, staleDate: nil),
                              dismissalPolicy: .default)
        }
        currentActivity = nil
    }
}
#endif
