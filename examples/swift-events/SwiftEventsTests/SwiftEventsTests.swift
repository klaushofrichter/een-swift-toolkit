import XCTest
@testable import SwiftEvents

final class SwiftEventsTests: XCTestCase {
    func testFormatEENTimestamp() {
        let date = Date(timeIntervalSince1970: 0)
        let result = formatEENTimestamp(date)
        XCTAssertTrue(result.contains("+00:00"), "Timestamp should use +00:00 format")
        XCTAssertTrue(result.hasPrefix("1970-01-01"), "Should format epoch correctly")
    }

    func testFormatEventTime() {
        let result = formatEventTime("2024-01-15T10:30:45.123+00:00")
        XCTAssertFalse(result.isEmpty, "Should produce a non-empty time string")
    }
}
