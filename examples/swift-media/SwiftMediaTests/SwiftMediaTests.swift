import XCTest
@testable import SwiftMedia

final class FormatDurationTests: XCTestCase {

    func testZeroSeconds() {
        XCTAssertEqual(formatDuration(0), "0:00")
    }

    func testSecondsOnly() {
        XCTAssertEqual(formatDuration(5), "0:05")
        XCTAssertEqual(formatDuration(59), "0:59")
    }

    func testMinutesAndSeconds() {
        XCTAssertEqual(formatDuration(60), "1:00")
        XCTAssertEqual(formatDuration(90), "1:30")
        XCTAssertEqual(formatDuration(3599), "59:59")
    }

    func testHoursMinutesSeconds() {
        XCTAssertEqual(formatDuration(3600), "1:00:00")
        XCTAssertEqual(formatDuration(3661), "1:01:01")
        XCTAssertEqual(formatDuration(7200), "2:00:00")
    }

    func testNegativeValue() {
        XCTAssertEqual(formatDuration(-1), "0:00")
    }

    func testInfinity() {
        XCTAssertEqual(formatDuration(Double.infinity), "0:00")
    }

    func testNaN() {
        XCTAssertEqual(formatDuration(Double.nan), "0:00")
    }

    func testFractionalSeconds() {
        // Should truncate, not round
        XCTAssertEqual(formatDuration(1.9), "0:01")
        XCTAssertEqual(formatDuration(59.999), "0:59")
    }
}

final class FormatEENTimestampTests: XCTestCase {

    func testUsesPlus0000Format() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01T00:00:00Z
        let result = formatEENTimestamp(date)
        XCTAssertTrue(result.hasSuffix("+00:00"),
                      "Timestamp should end with +00:00, got: \(result)")
        XCTAssertFalse(result.contains("Z"),
                       "Timestamp should not contain Z, got: \(result)")
    }

    func testContainsMilliseconds() {
        let date = Date(timeIntervalSince1970: 1000.123)
        let result = formatEENTimestamp(date)
        // Should contain millisecond component (.XXX)
        let regex = try! NSRegularExpression(pattern: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}")
        let range = NSRange(result.startIndex..., in: result)
        XCTAssertNotNil(regex.firstMatch(in: result, range: range),
                        "Timestamp should contain milliseconds, got: \(result)")
    }

    func testUTCTimezone() {
        // Create a date at a known UTC time
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2025, month: 6, day: 15, hour: 14, minute: 30, second: 0)
        let date = calendar.date(from: components)!
        let result = formatEENTimestamp(date)
        XCTAssertTrue(result.hasPrefix("2025-06-15T14:30:00"),
                      "Timestamp should reflect UTC time, got: \(result)")
    }
}

final class AppConfigTests: XCTestCase {

    func testDefaultProxyUrl() {
        // When no env var is set, should default to Cloudflare proxy
        // (env vars are not set in unit test context)
        XCTAssertTrue(AppConfig.proxyUrl.hasPrefix("https://"),
                      "Default proxy URL should be HTTPS, got: \(AppConfig.proxyUrl)")
    }

    func testDefaultClientId() {
        XCTAssertFalse(AppConfig.clientId.isEmpty, "Client ID should not be empty")
    }

    func testDefaultRedirectUri() {
        XCTAssertTrue(AppConfig.redirectUri.hasPrefix("https://"),
                      "Default redirect URI should be HTTPS, got: \(AppConfig.redirectUri)")
    }

    func testProxyUrlAndRedirectUriMatch() {
        // Both should point to the same proxy
        XCTAssertEqual(AppConfig.proxyUrl, AppConfig.redirectUri,
                       "Proxy URL and redirect URI should match by default")
    }
}
