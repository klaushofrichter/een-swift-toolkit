import Testing
import Foundation
@testable import EENApiToolkit

@Suite("Timestamp Formatting Tests")
struct TimestampTests {

    @Test("Converts Z suffix to +00:00")
    func convertsZSuffix() {
        #expect(formatTimestamp("2024-01-01T00:00:00.000Z") == "2024-01-01T00:00:00.000+00:00")
    }

    @Test("Converts Z without milliseconds")
    func convertsZWithoutMs() {
        #expect(formatTimestamp("2024-01-01T12:30:45Z") == "2024-01-01T12:30:45+00:00")
    }

    @Test("Returns unchanged if already +00:00")
    func alreadyCorrectFormat() {
        let ts = "2024-01-01T00:00:00.000+00:00"
        #expect(formatTimestamp(ts) == ts)
    }

    @Test("Preserves other timezone offsets")
    func preservesOtherOffsets() {
        #expect(formatTimestamp("2024-01-01T12:00:00.000+05:30") == "2024-01-01T12:00:00.000+05:30")
        #expect(formatTimestamp("2024-01-01T12:00:00.000-08:00") == "2024-01-01T12:00:00.000-08:00")
    }

    @Test("Returns unchanged for empty or malformed strings")
    func edgeCases() {
        #expect(formatTimestamp("") == "")
        #expect(formatTimestamp("2024-01-01") == "2024-01-01")
        #expect(formatTimestamp("not-a-timestamp") == "not-a-timestamp")
    }

    @Test("Is idempotent")
    func idempotent() {
        let first = formatTimestamp("2024-01-01T00:00:00.000Z")
        let second = formatTimestamp(first)
        #expect(first == second)
        #expect(second == "2024-01-01T00:00:00.000+00:00")
    }

    @Test("Formats Date to EEN format")
    func formatsDate() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01T00:00:00Z
        let result = formatTimestamp(date)
        #expect(result.hasSuffix("+00:00"))
        #expect(!result.hasSuffix("Z"))
        #expect(result.contains("2024-01-01"))
    }
}
