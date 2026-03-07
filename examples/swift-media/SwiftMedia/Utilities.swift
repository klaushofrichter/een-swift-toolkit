import Foundation

/// Format a Date to the EEN API timestamp format (+00:00, not Z).
func formatEENTimestamp(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter.string(from: date).replacingOccurrences(of: "Z", with: "+00:00")
}

/// Format seconds into a human-readable duration string (m:ss or h:mm:ss).
func formatDuration(_ seconds: Double) -> String {
    guard seconds.isFinite && seconds >= 0 else { return "0:00" }
    let totalSeconds = Int(seconds)
    let h = totalSeconds / 3600
    let m = (totalSeconds % 3600) / 60
    let s = totalSeconds % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
}
