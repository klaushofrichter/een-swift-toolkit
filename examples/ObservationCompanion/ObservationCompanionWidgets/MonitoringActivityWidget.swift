import WidgetKit
import SwiftUI

@main
struct ObservationCompanionWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonitoringActivityWidget()
    }
}

struct MonitoringActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MonitoringActivityAttributes.self) { context in
            // Lock Screen / banner presentation
            HStack(spacing: 12) {
                Text(context.state.latestEventEmoji)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.cameraName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context.state.latestEventDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(context.state.eventCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("events")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.latestEventEmoji)
                        .font(.title)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.eventCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.cameraName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(context.state.latestEventDescription)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Monitoring")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(context.state.lastEventTimestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Text(context.state.latestEventEmoji)
                    .font(.body)
                    .minimumScaleFactor(0.5)
            } compactTrailing: {
                Text(context.state.lastEventTimestamp, style: .timer)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: 42)
            } minimal: {
                Text(context.state.latestEventEmoji)
                    .font(.caption)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}
