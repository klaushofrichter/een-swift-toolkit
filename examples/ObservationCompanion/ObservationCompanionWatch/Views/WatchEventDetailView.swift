import SwiftUI

struct WatchEventDetailView: View {
    let event: WatchEvent
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var loadFailed = false

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Recorded image
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(boundingBoxOverlay)
                        .cornerRadius(8)
                } else if loadFailed {
                    HStack {
                        Image(systemName: "photo.slash")
                        Text("No image")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 40)
                }

                HStack {
                    Text(event.typeEmoji)
                        .font(.title3)
                    Text(event.typeName)
                        .font(.headline)
                }

                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                Label(event.cameraName, systemImage: "video")
                    .font(.caption2)
                    .foregroundColor(.blue)

                Label(Self.fullFormatter.string(from: event.timestamp), systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .monospacedDigit()

                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let seconds = Int(timeline.date.timeIntervalSince(event.timestamp))
                    Label(elapsedText(seconds: seconds), systemImage: "timer")
                        .font(.caption2)
                        .foregroundColor(seconds < 120 ? .white : .gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("")
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoading = true
        await withCheckedContinuation { continuation in
            connectivityManager.requestImage(for: event) { data in
                Task { @MainActor in
                    if let data {
                        imageData = data
                    } else {
                        loadFailed = true
                    }
                    isLoading = false
                    continuation.resume()
                }
            }
        }
    }

    @ViewBuilder
    private var boundingBoxOverlay: some View {
        GeometryReader { geo in
            ForEach(Array(event.boundingBoxes.enumerated()), id: \.offset) { _, box in
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(
                        width: box.width * geo.size.width,
                        height: box.height * geo.size.height
                    )
                    .position(
                        x: (box.x + box.width / 2) * geo.size.width,
                        y: (box.y + box.height / 2) * geo.size.height
                    )
            }
        }
    }

    private func elapsedText(seconds: Int) -> String {
        if seconds < 0 { return "" }
        if seconds < 5 { return "just now" }
        if seconds < 120 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m ago"
    }
}
