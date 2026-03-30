import Foundation

func formatEENTimestamp(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter.string(from: date).replacingOccurrences(of: "Z", with: "+00:00")
}

func formatEventTime(_ isoString: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let date = isoFormatter.date(from: isoString) else {
        // Try without fractional seconds
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        guard let d = basic.date(from: isoString) else { return isoString }
        return formatTime(d)
    }
    return formatTime(date)
}

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    formatter.timeZone = .current
    return formatter.string(from: date)
}
