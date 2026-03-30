import SwiftUI
import EENApiToolkit

struct LiveEventsView: View {
    let toolkit: EENToolkit
    @Binding var cameraId: String?
    @Binding var cameraName: String?

    @State private var liveEvents: [SSEEventItem] = []
    @State private var connectionStatus: String = "Disconnected"
    @State private var isConnected = false
    @State private var sseConnection: SSEConnection?
    @State private var subscriptionId: String?
    @State private var eventTypes: [String] = []
    @State private var selectedEvent: SSEEventItem?

    struct SSEEventItem: Identifiable {
        let id = UUID()
        let type: String
        let actorId: String
        let timestamp: String
        let eventId: String
        let rawEvent: SSEEvent
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(connectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("SSEStatus")
                Spacer()
                Text("\(liveEvents.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("SSEEventCount")
                Button(isConnected ? "Stop" : "Start") {
                    if isConnected {
                        disconnect()
                    } else {
                        Task { await connect() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isConnected ? .red : .orange)
                .accessibilityIdentifier("SSEToggleButton")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            if liveEvents.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bolt.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(isConnected ? "Waiting for events..." : "Tap Start to connect")
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("NoLiveEvents")
                Spacer()
            } else {
                List(liveEvents) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(friendlyName(event.type))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatEventTime(event.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            Text(event.type)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .monospaced()
                        }
                        .padding(.vertical, 2)
                    }
                    .foregroundColor(.primary)
                }
                .accessibilityIdentifier("LiveEventsList")
                .sheet(item: $selectedEvent) { event in
                    EventDetailView(title: friendlyName(event.type), encodable: event.rawEvent)
                }
            }
        }
        .onChange(of: cameraId) { _ in
            disconnect()
            liveEvents = []
            eventTypes = []
        }
        .onDisappear {
            disconnect()
        }
    }

    private var statusColor: Color {
        switch connectionStatus {
        case "Connected": return .green
        case "Connecting...": return .yellow
        default: return .red
        }
    }

    private func connect() async {
        guard let cameraId else { return }
        connectionStatus = "Connecting..."

        do {
            // Load event types if needed
            if eventTypes.isEmpty {
                let fieldValues = try await toolkit.events.listFieldValues(actor: "camera:\(cameraId)")
                eventTypes = fieldValues.type
            }

            guard !eventTypes.isEmpty else {
                connectionStatus = "No event types"
                return
            }

            let subscription = try await toolkit.eventSubscriptions.create(
                params: CreateEventSubscriptionParams(
                    sseFilters: [FilterCreate(
                        actors: ["camera:\(cameraId)"],
                        types: eventTypes.map { EventTypeFilter(id: $0) }
                    )]
                )
            )

            subscriptionId = subscription.id

            guard case .sse(let sseUrl) = subscription.deliveryConfig, let url = sseUrl else {
                connectionStatus = "No SSE URL"
                return
            }

            let connection = await toolkit.eventSubscriptions.connect(
                sseUrl: url,
                options: SSEConnectionOptions(
                    onEvent: { @Sendable event in
                        Task { @MainActor in
                            let item = SSEEventItem(
                                type: event.type,
                                actorId: event.actorId,
                                timestamp: event.startTimestamp,
                                eventId: event.id,
                                rawEvent: event
                            )
                            liveEvents.insert(item, at: 0)
                            // Keep max 100 events
                            if liveEvents.count > 100 {
                                liveEvents = Array(liveEvents.prefix(100))
                            }
                        }
                    },
                    onError: { @Sendable error in
                        Task { @MainActor in
                            connectionStatus = "Error: \(error.localizedDescription)"
                        }
                    },
                    onStatusChange: { @Sendable status in
                        Task { @MainActor in
                            switch status {
                            case .connected:
                                connectionStatus = "Connected"
                                isConnected = true
                            case .connecting:
                                connectionStatus = "Connecting..."
                            case .disconnected:
                                connectionStatus = "Disconnected"
                                isConnected = false
                            case .error:
                                connectionStatus = "Error"
                                isConnected = false
                            }
                        }
                    }
                )
            )
            sseConnection = connection
            isConnected = true
            connectionStatus = "Connected"
        } catch {
            connectionStatus = "Error: \(error.localizedDescription)"
            isConnected = false
        }
    }

    private func disconnect() {
        sseConnection?.close()
        sseConnection = nil
        isConnected = false
        connectionStatus = "Disconnected"

        if let subId = subscriptionId {
            Task {
                try? await toolkit.eventSubscriptions.delete(id: subId)
            }
            subscriptionId = nil
        }
    }

    private func friendlyName(_ type: String) -> String {
        var name = type
        if name.hasPrefix("een.") { name = String(name.dropFirst(4)) }
        if let dotIndex = name.lastIndex(of: ".") { name = String(name[..<dotIndex]) }
        var result = ""
        for char in name {
            if char.isUppercase && !result.isEmpty {
                result.append(" ")
            }
            result.append(char)
        }
        return result.prefix(1).uppercased() + result.dropFirst()
    }
}
