import Foundation

/// Service for Event API endpoints.
public struct EventService: Sendable {
    let client: HTTPClient

    /// List events with required actor, type, and time filters.
    public func list(params: ListEventsParams) async throws -> PaginatedResult<Event> {
        try await client.request(Endpoint(path: "/api/v3.0/events", queryItems: params.toQueryItems()))
    }

    /// Get a single event by ID.
    public func get(id: String, include: [String]? = nil) async throws -> Event {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/events/\(id)", queryItems: queryItems))
    }

    /// List available event types.
    public func listTypes(params: ListEventTypesParams = .init()) async throws -> PaginatedResult<EventType> {
        try await client.request(Endpoint(path: "/api/v3.0/eventTypes", queryItems: params.toQueryItems()))
    }

    /// List possible event field values for a given actor.
    public func listFieldValues(actor: String) async throws -> EventFieldValues {
        let queryItems = [URLQueryItem(name: "actor", value: actor)]
        return try await client.request(Endpoint(path: "/api/v3.0/events:listFieldValues", queryItems: queryItems))
    }
}
