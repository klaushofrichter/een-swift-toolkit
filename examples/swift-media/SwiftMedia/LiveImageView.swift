import SwiftUI
import EENSwiftToolkit

struct LiveImageView: View {
    let toolkit: EENToolkit
    @Binding var cameraId: String?
    @State private var image: UIImage?
    @State private var timestamp: String?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var autoRefresh = true
    @State private var refreshTask: Task<Void, Never>?

    private let refreshInterval: TimeInterval = 5

    var body: some View {
        VStack(spacing: 12) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
                    .accessibilityIdentifier("LiveImage")
            } else if isLoading {
                ProgressView("Loading live image...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if cameraId == nil {
                Text("Select a camera to view live image")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }

            if let timestamp {
                Text(timestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("LiveTimestamp")
            }

            HStack(spacing: 16) {
                Button {
                    Task { await fetchLiveImage() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .accessibilityIdentifier("RefreshButton")

                Toggle(isOn: $autoRefresh) {
                    Text("Auto-refresh")
                        .font(.subheadline)
                }
                .toggleStyle(.switch)
                .accessibilityIdentifier("AutoRefreshToggle")
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onChange(of: cameraId) { _ in
            restartAutoRefresh()
        }
        .onChange(of: autoRefresh) { _ in
            restartAutoRefresh()
        }
        .onAppear {
            restartAutoRefresh()
        }
        .onDisappear {
            refreshTask?.cancel()
        }
    }

    private func restartAutoRefresh() {
        refreshTask?.cancel()
        guard autoRefresh, cameraId != nil else { return }

        refreshTask = Task {
            while !Task.isCancelled {
                await fetchLiveImage()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }

    private func fetchLiveImage() async {
        guard let cameraId else { return }
        isLoading = image == nil
        errorMessage = nil

        do {
            let params = GetLiveImageParams(deviceId: cameraId)
            let result = try await toolkit.media.getLiveImage(params: params)
            if let uiImage = UIImage(data: result.imageData) {
                image = uiImage
                timestamp = result.timestamp
            } else {
                errorMessage = "Could not decode image data"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
