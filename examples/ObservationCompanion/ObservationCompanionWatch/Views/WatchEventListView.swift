import SwiftUI

struct WatchEventListView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var navigationPath = NavigationPath()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if connectivityManager.events.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "applewatch.radiowaves.left.and.right")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Waiting for events...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if !connectivityManager.cameraName.isEmpty {
                            Button {
                                navigationPath.append("liveImage")
                            } label: {
                                Text(connectivityManager.cameraName)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    List {
                        Button {
                            navigationPath.append("liveImage")
                        } label: {
                            Text(connectivityManager.cameraName.isEmpty ? "Events" : connectivityManager.cameraName)
                                .font(.headline)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)

                        ForEach(connectivityManager.events) { event in
                            NavigationLink(value: event.id) {
                                WatchEventRowView(event: event, timeFormatter: timeFormatter)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: UUID.self) { eventId in
                if let event = connectivityManager.events.first(where: { $0.id == eventId }) {
                    WatchEventDetailView(event: event)
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "liveImage" {
                    WatchLiveImageView()
                }
            }
        }
        .onChange(of: connectivityManager.cameraChangeCount) {
            navigationPath = NavigationPath()
        }
    }
}
