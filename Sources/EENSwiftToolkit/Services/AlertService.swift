import Foundation

/// Service for Alert API endpoints.
public struct AlertService: Sendable {
    let client: HTTPClient

    /// List alerts with optional filters.
    public func list(params: ListAlertsParams = .init()) async throws -> PaginatedResult<Alert> {
        try await client.request(Endpoint(path: "/api/v3.0/alerts", queryItems: params.toQueryItems()))
    }

    /// Get a single alert by ID.
    public func get(id: String, include: [String]? = nil) async throws -> Alert {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/alerts/\(id)", queryItems: queryItems))
    }

    /// List available alert types.
    public func listTypes(params: ListAlertTypesParams = .init()) async throws -> PaginatedResult<AlertType> {
        try await client.request(Endpoint(path: "/api/v3.0/alerts:listTypes", queryItems: params.toQueryItems()))
    }
}
