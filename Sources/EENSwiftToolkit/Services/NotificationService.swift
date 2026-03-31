import Foundation

/// Service for Notification API endpoints.
public struct NotificationService: Sendable {
    let client: HTTPClient

    /// List notifications with optional filters.
    public func list(params: ListNotificationsParams = .init()) async throws -> PaginatedResult<Notification> {
        try await client.request(Endpoint(path: "/api/v3.0/notifications", queryItems: params.toQueryItems()))
    }

    /// Get a single notification by ID.
    public func get(id: String) async throws -> Notification {
        try await client.request(Endpoint(path: "/api/v3.0/notifications/\(id)"))
    }
}
