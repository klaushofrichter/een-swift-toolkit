import SwiftUI
import EENSwiftToolkit

struct EventTypesView: View {
    let toolkit: EENToolkit
    @Binding var cameraId: String?

    @State private var eventTypes: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading event types...")
                    .accessibilityIdentifier("EventTypesLoading")
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadEventTypes() } }
                }
                .padding()
            } else if eventTypes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No event types found")
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("NoEventTypes")
            } else {
                List(eventTypes, id: \.self) { type in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(friendlyName(type))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(type)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityIdentifier("EventTypesList")
            }
        }
        .onChange(of: cameraId) { _ in
            Task { await loadEventTypes() }
        }
        .task {
            await loadEventTypes()
        }
    }

    private func loadEventTypes() async {
        guard let cameraId else { return }
        isLoading = true
        errorMessage = nil
        do {
            let fieldValues = try await toolkit.events.listFieldValues(actor: "camera:\(cameraId)")
            eventTypes = fieldValues.type.sorted()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func friendlyName(_ type: String) -> String {
        // "een.motionDetectionEvent.v1" -> "Motion Detection Event"
        var name = type
        if name.hasPrefix("een.") { name = String(name.dropFirst(4)) }
        if let dotIndex = name.lastIndex(of: ".") { name = String(name[..<dotIndex]) }
        // CamelCase to spaced
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
