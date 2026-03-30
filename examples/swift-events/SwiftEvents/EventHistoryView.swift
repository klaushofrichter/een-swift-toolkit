import SwiftUI
import EENApiToolkit

struct EventHistoryView: View {
    let toolkit: EENToolkit
    @Binding var cameraId: String?

    @State private var events: [Event] = []
    @State private var eventTypes: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hoursBack: Double = 1
    @State private var selectedEvent: Event?

    var body: some View {
        VStack(spacing: 0) {
            // Controls
            VStack(spacing: 8) {
                HStack {
                    Text("Past \(Int(hoursBack))h")
                        .font(.subheadline)
                        .monospacedDigit()
                    Slider(value: $hoursBack, in: 1...24, step: 1)
                        .accessibilityIdentifier("HoursSlider")
                    Button("Load") {
                        Task { await loadEvents() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .accessibilityIdentifier("LoadEventsButton")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            // Events list
            if isLoading {
                Spacer()
                ProgressView("Loading events...")
                    .accessibilityIdentifier("EventsLoading")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else if events.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No events found")
                        .foregroundColor(.secondary)
                    Text("Tap Load to fetch events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("NoEvents")
                Spacer()
            } else {
                List(events) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(friendlyName(event.type))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatEventTime(event.startTimestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            Text(event.type)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .monospaced()
                            Text(event.id)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .monospaced()
                                .lineLimit(1)
                        }
                        .padding(.vertical, 2)
                    }
                    .foregroundColor(.primary)
                }
                .accessibilityIdentifier("EventHistoryList")
                .sheet(item: $selectedEvent) { event in
                    EventDetailView(title: friendlyName(event.type), encodable: event)
                }
            }
        }
        .onChange(of: cameraId) { _ in
            events = []
            eventTypes = []
            Task { await loadEventTypesAndEvents() }
        }
        .task(id: cameraId) {
            if eventTypes.isEmpty {
                await loadEventTypesAndEvents()
            }
        }
    }

    private func loadEventTypesAndEvents() async {
        guard let cameraId else { return }
        do {
            let fieldValues = try await toolkit.events.listFieldValues(actor: "camera:\(cameraId)")
            eventTypes = fieldValues.type
        } catch {
            print("[EventHistory] Failed to load event types: \(error)")
        }
        await loadEvents()
    }

    private func loadEvents() async {
        guard let cameraId, !eventTypes.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let startTime = formatEENTimestamp(Date().addingTimeInterval(-hoursBack * 3600))
            let endTime = formatEENTimestamp(Date())
            var params = ListEventsParams(
                actor: "camera:\(cameraId)",
                typeIn: eventTypes,
                startTimestampGte: startTime
            )
            params.startTimestampLte = endTime
            params.pageSize = 50
            params.sort = "-startTimestamp"
            let result = try await toolkit.events.list(params: params)
            events = result.results
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
