import Foundation

/// Service for Layout API endpoints (full CRUD).
public struct LayoutService: Sendable {
    let client: HTTPClient

    /// List layouts with optional filters.
    public func list(params: ListLayoutsParams = .init()) async throws -> PaginatedResult<Layout> {
        try await client.request(Endpoint(path: "/api/v3.0/layouts", queryItems: params.toQueryItems()))
    }

    /// Get a single layout by ID.
    public func get(id: String, include: [String]? = nil) async throws -> Layout {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/layouts/\(id)", queryItems: queryItems))
    }

    /// Create a new layout.
    public func create(params: CreateLayoutParams) async throws -> Layout {
        try await client.request(Endpoint(method: .post, path: "/api/v3.0/layouts", body: params))
    }

    /// Update an existing layout.
    public func update(id: String, params: UpdateLayoutParams) async throws -> Layout {
        try await client.request(Endpoint(method: .put, path: "/api/v3.0/layouts/\(id)", body: params))
    }

    /// Delete a layout.
    public func delete(id: String) async throws {
        try await client.requestVoid(Endpoint(method: .delete, path: "/api/v3.0/layouts/\(id)"))
    }
}
