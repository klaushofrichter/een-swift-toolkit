import Foundation

/// Service for Feed API endpoints.
public struct FeedService: Sendable {
    let client: HTTPClient

    /// List feeds with optional filters.
    public func list(params: ListFeedsParams = .init()) async throws -> PaginatedResult<Feed> {
        try await client.request(Endpoint(path: "/api/v3.0/feeds", queryItems: params.toQueryItems()))
    }
}
