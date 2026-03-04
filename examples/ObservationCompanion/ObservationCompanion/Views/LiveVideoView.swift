import SwiftUI
import AVFoundation

struct LiveVideoView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                if appState.isVideoPlaying, let player = appState.hlsPlayer {
                    VideoPlayerView(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }

                if !appState.isVideoPlaying && appState.videoError == nil {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text("Loading HD stream...")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .accessibilityIdentifier("StreamLoadingView")
                }

                if let error = appState.videoError {
                    VStack(spacing: 8) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                        Text("Stream Error")
                            .foregroundColor(.white)
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .accessibilityIdentifier("StreamErrorView")
                }

                if appState.isVideoPlaying {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("LIVE HD")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(8)
                            .accessibilityIdentifier("LiveBadge")
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

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
