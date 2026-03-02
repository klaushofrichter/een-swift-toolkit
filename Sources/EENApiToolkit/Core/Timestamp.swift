import Foundation

/// Convert an ISO 8601 timestamp to the format required by the EEN API.
///
/// The EEN API requires timestamps in `+00:00` format, not `Z` format.
/// This function converts `2024-01-01T00:00:00.000Z` to `2024-01-01T00:00:00.000+00:00`.
///
/// Timestamps already in `+00:00` or other offset formats are returned unchanged.
///
/// - Parameter timestamp: ISO 8601 timestamp string.
/// - Returns: Timestamp with `+00:00` suffix instead of `Z`.
public func formatTimestamp(_ timestamp: String) -> String {
    if timestamp.hasSuffix("+00:00") {
        return timestamp
    }
    if timestamp.hasSuffix("Z") {
        return String(timestamp.dropLast()) + "+00:00"
    }
    return timestamp
}

/// Format a `Date` as an EEN API timestamp string.
///
/// Returns a string in `yyyy-MM-dd'T'HH:mm:ss.SSS+00:00` format.
///
/// - Parameter date: The date to format.
/// - Returns: EEN-compatible timestamp string.
public func formatTimestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let iso = formatter.string(from: date)
    return formatTimestamp(iso)
}
