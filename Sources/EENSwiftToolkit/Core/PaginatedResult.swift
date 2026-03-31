import Foundation

/// A paginated response from the EEN API.
public struct PaginatedResult<T: Decodable & Sendable>: Decodable, Sendable {
    /// The items in this page.
    public let results: [T]

    /// Token for fetching the next page, if available.
    public let nextPageToken: String?

    /// Token for fetching the previous page, if available.
    public let prevPageToken: String?

    /// Total number of items across all pages, if provided by the API.
    public let totalSize: Int?

    public init(results: [T], nextPageToken: String? = nil, prevPageToken: String? = nil, totalSize: Int? = nil) {
        self.results = results
        self.nextPageToken = Self.nilIfEmpty(nextPageToken)
        self.prevPageToken = Self.nilIfEmpty(prevPageToken)
        self.totalSize = totalSize
    }

    // The EEN API returns "" (empty string) instead of null when there are
    // no more pages. The auto-synthesized Decodable init bypasses our custom
    // init, so we must implement init(from:) manually to normalize empty
    // page tokens to nil. This matches the JS/TS truthy convention where
    // `while (pageToken)` naturally stops on "".
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([T].self, forKey: .results)
        self.nextPageToken = Self.nilIfEmpty(try container.decodeIfPresent(String.self, forKey: .nextPageToken))
        self.prevPageToken = Self.nilIfEmpty(try container.decodeIfPresent(String.self, forKey: .prevPageToken))
        self.totalSize = try container.decodeIfPresent(Int.self, forKey: .totalSize)
    }

    private enum CodingKeys: String, CodingKey {
        case results, nextPageToken, prevPageToken, totalSize
    }

    private static func nilIfEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
