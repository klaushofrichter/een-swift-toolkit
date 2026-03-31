import SwiftUI
import AVFoundation
import EENSwiftToolkit

struct RecordedVideoView: View {
    let toolkit: EENToolkit
    @Binding var cameraId: String?
    @Binding var selectedDate: Date
    @EnvironmentObject var authState: AuthState
    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var mediaInfo: String?
    @State private var playerObservation: NSKeyValueObservation?
    @State private var playbackProgress: Double = 0
    @State private var playbackDuration: Double = 0
    @State private var playbackPosition: Double = 0
    @State private var isScrubbing = false
    @State private var timeObserver: Any?

    var body: some View {
        ScrollView {
        VStack(spacing: 16) {
            // Time picker
            HStack {
                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .accessibilityIdentifier("VideoTimePicker")

                Button("Go") {
                    Task { await loadVideo() }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("VideoGoButton")

                Button("Now") {
                    selectedDate = Date().addingTimeInterval(-300)
                    Task { await loadVideo() }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            if let player {
                VideoPlayerView(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .accessibilityIdentifier("VideoPlayer")
            } else if isLoading {
                ProgressView("Loading video...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if cameraId == nil {
                Text("Select a camera to view recorded video")
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
            } else {
                Text("Select a time and tap Go to load video")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }

            if player != nil {
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { isScrubbing ? playbackPosition : playbackPosition },
                            set: { newValue in
                                playbackPosition = newValue
                                isScrubbing = true
                            }
                        ),
                        in: 0...max(playbackDuration, 1),
                        onEditingChanged: { editing in
                            if !editing {
                                isScrubbing = false
                                let time = CMTime(seconds: playbackPosition, preferredTimescale: 600)
                                player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                            }
                        }
                    )

                    HStack {
                        Text(formatDuration(playbackPosition))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                        Spacer()
                        Text(formatDuration(playbackDuration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal)
            }

            if let mediaInfo {
                Text(mediaInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .accessibilityIdentifier("MediaInfo")
            }

            HStack(spacing: 16) {
                Button {
                    player?.play()
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .disabled(player == nil)

                Button {
                    player?.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(player == nil)
            }

                Spacer()
            }
        }
        .onChange(of: cameraId) { _ in
            stopPlayback()
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private func loadVideo() async {
        guard let cameraId else { return }
        stopPlayback()
        isLoading = true
        errorMessage = nil
        mediaInfo = nil

        do {
            // Initialize media session (best-effort)
            try? await toolkit.media.initMediaSession(deviceId: cameraId)

            // Query for media intervals at the selected time
            let ts = formatTimestamp(selectedDate)
            var params = ListMediaParams(
                deviceId: cameraId,
                type: .main,
                mediaType: .video,
                startTimestamp: ts
            )
            params.include = ["hlsUrl"]

            let result = try await toolkit.media.listMedia(params: params)
            guard let interval = result.results.first, let hlsUrl = interval.hlsUrl else {
                errorMessage = "No video available at this time"
                isLoading = false
                return
            }

            mediaInfo = "\(interval.startTimestamp) — \(interval.endTimestamp)"

            setupPlayer(hlsUrl: hlsUrl)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func setupPlayer(hlsUrl: String) {
        guard let url = URL(string: hlsUrl) else {
            errorMessage = "Invalid HLS URL"
            return
        }

        let token = authState.token ?? ""
        let headers = ["Authorization": "Bearer \(token)"]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)

        let newPlayer = AVPlayer(playerItem: item)

        playerObservation = item.observe(\.status) { item, _ in
            Task { @MainActor in
                switch item.status {
                case .failed:
                    errorMessage = item.error?.localizedDescription ?? "Playback failed"
                default:
                    break
                }
            }
        }

        player = newPlayer

        // Periodic time observer for progress tracking
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak newPlayer] time in
            guard !isScrubbing, let currentItem = newPlayer?.currentItem else { return }
            let duration = currentItem.duration
            if duration.isNumeric {
                playbackDuration = duration.seconds
                playbackPosition = time.seconds
            }
        }

        newPlayer.play()
    }

    private func stopPlayback() {
        if let observer = timeObserver, let p = player {
            p.removeTimeObserver(observer)
        }
        timeObserver = nil
        player?.pause()
        player = nil
        playerObservation?.invalidate()
        playerObservation = nil
        playbackPosition = 0
        playbackDuration = 0
    }

    private func formatTimestamp(_ date: Date) -> String {
        formatEENTimestamp(date)
    }
}

// MARK: - Video Player UIView wrapper

struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

class PlayerUIView: UIView {
    let playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
