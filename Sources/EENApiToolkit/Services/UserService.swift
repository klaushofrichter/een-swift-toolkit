import Foundation

/// Service for User API endpoints.
public struct UserService: Sendable {
    let client: HTTPClient

    /// Get the currently authenticated user.
    public func getCurrentUser() async throws -> User {
        try await client.request(Endpoint(path: "/api/v3.0/users/self"))
    }

    /// List all users with optional pagination and filtering.
    public func list(params: ListUsersParams = .init()) async throws -> PaginatedResult<User> {
        try await client.request(Endpoint(path: "/api/v3.0/users", queryItems: params.toQueryItems()))
    }

    /// Get a single user by ID.
    public func get(id: String, include: [String]? = nil) async throws -> User {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/users/\(id)", queryItems: queryItems))
    }
}
