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
                if context.state.latestEventEmoji.isEmpty {
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text(context.state.latestEventEmoji)
                        .font(.largeTitle)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.cameraName)
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
            .widgetURL(Self.eventURL(context.state.latestEventId))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if context.state.latestEventEmoji.isEmpty {
                        Image("AppIconImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Text(context.state.latestEventEmoji)
                            .font(.title)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.eventCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.cameraName)
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
                        if let timestamp = context.state.lastEventTimestamp {
                            Text(timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                if context.state.latestEventEmoji.isEmpty {
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Text(context.state.latestEventEmoji)
                        .font(.body)
                        .minimumScaleFactor(0.5)
                }
            } compactTrailing: {
                if let timestamp = context.state.lastEventTimestamp {
                    Text(timestamp, style: .timer)
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                        .frame(maxWidth: 42)
                }
            } minimal: {
                if context.state.latestEventEmoji.isEmpty {
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text(context.state.latestEventEmoji)
                        .font(.caption)
                        .minimumScaleFactor(0.5)
                }
            }
            .widgetURL(Self.eventURL(context.state.latestEventId))
        }
    }

    private static func eventURL(_ eventId: String?) -> URL? {
        guard let eventId else { return nil }
        return URL(string: "eenobserve://event/\(eventId)")
    }
}
