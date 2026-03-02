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
        self.nextPageToken = nextPageToken
        self.prevPageToken = prevPageToken
        self.totalSize = totalSize
    }
}
