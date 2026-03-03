import SwiftUI

struct TokenCountdownView: View {
    @EnvironmentObject var appState: AppState

    private var isQRMode: Bool {
        if case .qrCode = appState.authMode { return true }
        return false
    }

    private var progress: Double {
        let total = appState.tokenTTL
        let remaining = Double(appState.tokenSecondsRemaining)
        return max(0, min(1, remaining / total))
    }

    private var timeString: String {
        let seconds = appState.tokenSecondsRemaining
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private var barColor: Color {
        let remaining = appState.tokenSecondsRemaining
        if remaining < 300 { return .red }
        if remaining < 900 { return .orange }
        return .green
    }

    var body: some View {
        if isQRMode {
            HStack(spacing: 6) {
                Text(timeString)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(barColor)
                    .monospacedDigit()

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor)
                            .frame(width: geometry.size.width * progress, height: 6)
                            .animation(.linear(duration: 1), value: progress)
                    }
                }
                .frame(width: 60, height: 6)
            }
        } else {
            // OAuth mode: show authenticated indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("OAuth")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}
