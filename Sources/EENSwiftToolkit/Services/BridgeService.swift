import Foundation

/// Service for Bridge API endpoints.
public struct BridgeService: Sendable {
    let client: HTTPClient

    /// List bridges with optional filters.
    public func list(params: ListBridgesParams = .init()) async throws -> PaginatedResult<Bridge> {
        try await client.request(Endpoint(path: "/api/v3.0/bridges", queryItems: params.toQueryItems()))
    }

    /// Get a single bridge by ID.
    public func get(id: String, include: [String]? = nil) async throws -> Bridge {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/bridges/\(id)", queryItems: queryItems))
    }
}
