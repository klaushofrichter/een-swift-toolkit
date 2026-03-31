import Foundation

/// Event metric time-series data point.
public struct EventMetricDataPoint: Codable, Sendable {
    public let timestamp: String
    public let count: Int
}

/// Service for Event Metrics API endpoints.
public struct EventMetricService: Sendable {
    let client: HTTPClient

    /// Get event metrics (time-series data).
    public func getMetrics(
        actor: String,
        typeIn: [String],
        startTimestampGte: String,
        startTimestampLte: String? = nil,
        granularity: String? = nil,
        pageSize: Int? = nil,
        pageToken: String? = nil
    ) async throws -> PaginatedResult<EventMetricDataPoint> {
        var b = QueryItemBuilder()
        b.add("actor", actor)
        b.addIn("type", typeIn)
        b.addGte("startTimestamp", startTimestampGte)
        b.addLte("startTimestamp", startTimestampLte)
        b.add("granularity", granularity)
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        return try await client.request(Endpoint(path: "/api/v3.0/events:metrics", queryItems: b.items))
    }
}
