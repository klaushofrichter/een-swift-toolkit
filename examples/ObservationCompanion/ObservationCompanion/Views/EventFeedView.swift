import SwiftUI
import EENApiToolkit

struct EventFeedView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedEvent: CameraEvent?
    @State private var showEventTypePicker = false
    @State private var hasNewEvents = false
    @State private var isAtTop = true
    @State private var previousEventCount = 0

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private var displayedEvents: [CameraEvent] {
        if appState.showSSEEvents {
            return appState.events
        }
        return appState.events.filter { !$0.type.hasPrefix("sse_") }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    showEventTypePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Events")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .accessibilityIdentifier("EventFilterButton")
                Spacer()
                if hasNewEvents {
                    Button {
                        hasNewEvents = false
                    } label: {
                        Text("new events")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                Button {
                    appState.refreshHistory()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("EventRefreshButton")
                Button {
                    appState.isMuted.toggle()
                    if !appState.isMuted {
                        SoundPlayer.shared.play()
                    }
                } label: {
                    Image(systemName: appState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundColor(appState.isMuted ? .gray : .blue)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("EventMuteButton")
                Text("\(displayedEvents.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .monospacedDigit()
                    .accessibilityIdentifier("EventCount")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.9))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("EventFeedHeader")

            Divider()
                .background(Color.gray.opacity(0.3))

            if let event = selectedEvent {
                EventDetailInline(
                    event: event,
                    toolkit: appState.toolkit,
                    cameraId: appState.cameraId,
                    cameraName: appState.cameraName,
                    onDismiss: { selectedEvent = nil }
                )
            } else if displayedEvents.isEmpty {
                VStack(spacing: 8) {
                    Text("Waiting for events...")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
                .accessibilityIdentifier("WaitingForEvents")
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            Color.clear
                                .frame(height: 0)
                                .id("top")
                                .onAppear { isAtTop = true }
                                .onDisappear { isAtTop = false }

                            ForEach(displayedEvents) { event in
                                EventRow(event: event, timeFormatter: timeFormatter)
                                    .onTapGesture { selectedEvent = event }
                            }
                        }
                    }
                    .background(Color.black.opacity(0.8))
                    .accessibilityIdentifier("EventList")
                    .onChange(of: hasNewEvents) {
                        if !hasNewEvents {
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: displayedEvents.count) {
            let newCount = displayedEvents.count
            if newCount > previousEventCount && !isAtTop && previousEventCount > 0 {
                hasNewEvents = true
            }
            if isAtTop {
                hasNewEvents = false
            }
            previousEventCount = newCount
        }
        .sheet(isPresented: $showEventTypePicker) {
            EventTypePickerSheet(
                availableTypes: appState.availableEventTypes,
                activeTypes: appState.activeEventTypes,
                currentDuration: appState.historyDuration,
                currentShowSSEEvents: appState.showSSEEvents
            ) { newTypes, duration, showSSE in
                appState.showSSEEvents = showSSE
                appState.applyEventFilter(newTypes, duration: duration)
            }
        }
    }
}

// MARK: - Event Type Picker

private struct EventTypePickerSheet: View {
    let availableTypes: [String]
    let activeTypes: [String]
    let currentDuration: TimeInterval
    let currentShowSSEEvents: Bool
    let onApply: ([String], TimeInterval, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []
    @State private var selectedDuration: TimeInterval = 86400
    @State private var showSSEEvents: Bool = false

    private static let durationOptions: [(label: String, value: TimeInterval)] = [
        ("10 min", 600),
        ("1 hour", 3600),
        ("24 hours", 86400),
        ("1 week", 604800),
    ]

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Button("Select All") {
                            selected = Set(availableTypes)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        Spacer()
                        Button("Select None") {
                            selected.removeAll()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    .listRowBackground(Color(white: 0.15))
                }

                Section {
                    ForEach(availableTypes, id: \.self) { type in
                        Button {
                            if selected.contains(type) {
                                selected.remove(type)
                            } else {
                                selected.insert(type)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(type) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selected.contains(type) ? .blue : .gray)
                                Text(EventTypeHash.displayName(type))
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                } header: {
                    Text("\(selected.count) of \(availableTypes.count) selected")
                }

                Section {
                    ForEach(Self.durationOptions, id: \.value) { option in
                        Button {
                            selectedDuration = option.value
                        } label: {
                            HStack {
                                Text(option.label)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedDuration == option.value {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                } header: {
                    Text("History Duration")
                }

                Section {
                    Toggle(isOn: $showSSEEvents) {
                        Text("Show SSE Events")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(white: 0.15))
                } header: {
                    Text("Display")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.1))
            .navigationTitle("Event Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        let types = availableTypes.filter { selected.contains($0) }
                        onApply(types.isEmpty ? availableTypes : types, selectedDuration, showSSEEvents)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selected = Set(activeTypes)
                selectedDuration = currentDuration
                showSSEEvents = currentShowSSEEvents
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Event Row

private struct EventRow: View {
    let event: CameraEvent
    let timeFormatter: DateFormatter

    static func elapsedText(seconds: Int) -> String {
        if seconds < 0 { return "" }
        if seconds < 5 { return "just now" }
        if seconds < 120 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours < 24 { return "\(hours)h \(mins)m ago" }
        let days = hours / 24
        let hrs = hours % 24
        return "\(days)d \(hrs)h ago"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(event.typeEmoji)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(EventTypeHash.displayName(event.type))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(event.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(timeFormatter.string(from: event.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .monospacedDigit()
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let seconds = Int(timeline.date.timeIntervalSince(event.timestamp))
                    Text(Self.elapsedText(seconds: seconds))
                        .font(.caption2)
                        .foregroundColor(seconds < 120 ? .white : .gray.opacity(0.7))
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())

        Divider()
            .background(Color.gray.opacity(0.2))
    }
}

// MARK: - Event Detail

private struct EventDetailInline: View {
    let event: CameraEvent
    let toolkit: EENToolkit
    let cameraId: String
    let cameraName: String
    let onDismiss: () -> Void
    @State private var image: UIImage?
    @State private var imageError: String?
    @State private var isLoading = false

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    private var isInternalEvent: Bool {
        event.type.hasPrefix("sse_")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(event.typeEmoji) \(EventTypeHash.displayName(event.type))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Button("Done") { onDismiss() }
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.9))

            Divider()
                .background(Color.gray.opacity(0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                                let seconds = Int(timeline.date.timeIntervalSince(event.timestamp))
                                HStack(spacing: 4) {
                                    Text("\(Self.fullFormatter.string(from: event.timestamp)) -")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Text(EventRow.elapsedText(seconds: seconds))
                                        .font(.subheadline)
                                        .foregroundColor(seconds < 120 ? .white : .gray.opacity(0.7))
                                }
                            }
                        }
                        DetailRow(label: "Actor", value: "\(event.actorId) - \(cameraName)")
                    }

                    if isInternalEvent {
                        if !event.raw.isEmpty {
                            Text(event.raw)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                        }
                    } else if isLoading {
                        ProgressView("Loading image...")
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    } else if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if let imageError {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text(imageError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding()
            }
            .background(Color(white: 0.1))
        }
        .task { await loadImage() }
    }

    private func loadImage() async {
        guard !isInternalEvent else { return }
        isLoading = true
        do {
            var params = GetRecordedImageParams()
            params.timestampGte = formatTimestamp(event.timestamp)
            params.type = .preview
            params.targetWidth = 640
            let result = try await toolkit.media.getRecordedImage(deviceId: cameraId, params: params)
            if let uiImage = UIImage(data: result.imageData) {
                image = uiImage
            } else {
                imageError = "Could not decode image data"
            }
        } catch {
            imageError = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Camera Picker

struct CameraPickerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var cameras: [(id: String, name: String)] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""

    private var filteredCameras: [(id: String, name: String)] {
        if searchText.isEmpty { return cameras }
        let query = searchText.lowercased()
        return cameras.filter {
            $0.name.lowercased().contains(query) || $0.id.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading && cameras.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading cameras...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredCameras, id: \.id) { camera in
                            Button {
                                appState.switchCamera(to: camera.id)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(camera.name)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        Text(camera.id)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .monospaced()
                                    }
                                    Spacer()
                                    if camera.id == appState.cameraId {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .listRowBackground(Color(white: 0.15))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Filter cameras")
                }
            }
            .background(Color(white: 0.1))
            .navigationTitle("Cameras (\(cameras.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await loadAllCameras() }
        }
        .preferredColorScheme(.dark)
    }

    private func loadAllCameras() async {
        do {
            var allCameras: [(id: String, name: String)] = []
            var pageToken: String? = nil
            repeat {
                let params = ListCamerasParams(pageSize: 100, pageToken: pageToken)
                let response = try await appState.toolkit.cameras.list(params: params)
                allCameras.append(contentsOf: response.results.map { ($0.id, $0.name) })
                cameras = allCameras
                pageToken = response.nextPageToken
            } while pageToken != nil
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .textSelection(.enabled)
        }
    }
}
