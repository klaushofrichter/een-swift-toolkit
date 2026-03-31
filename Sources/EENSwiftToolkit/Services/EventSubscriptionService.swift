import Foundation

/// Service for Event Subscription API endpoints (CRUD + SSE streaming).
public struct EventSubscriptionService: Sendable {
    let client: HTTPClient
    let authState: AuthState

    /// List event subscriptions.
    public func list(params: ListEventSubscriptionsParams = .init()) async throws -> PaginatedResult<EventSubscription> {
        try await client.request(Endpoint(path: "/api/v3.0/eventSubscriptions", queryItems: params.toQueryItems()))
    }

    /// Get a single event subscription by ID.
    public func get(id: String) async throws -> EventSubscription {
        try await client.request(Endpoint(path: "/api/v3.0/eventSubscriptions/\(id)"))
    }

    /// Create a new event subscription (SSE or webhook).
    public func create(params: CreateEventSubscriptionParams) async throws -> EventSubscription {
        try await client.request(Endpoint(method: .post, path: "/api/v3.0/eventSubscriptions", body: params))
    }

    /// Delete an event subscription.
    public func delete(id: String) async throws {
        try await client.requestVoid(Endpoint(method: .delete, path: "/api/v3.0/eventSubscriptions/\(id)"))
    }

    /// Connect to an SSE event stream using a callback-based interface.
    @MainActor
    public func connect(sseUrl: String, options: SSEConnectionOptions) -> SSEConnection {
        let token = authState.token ?? ""
        return SSEConnection(url: sseUrl, token: token, options: options)
    }

    /// Connect to an SSE event stream as an AsyncSequence.
    public func eventStream(sseUrl: String) -> AsyncThrowingStream<SSEEvent, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                let currentToken = self.authState.token ?? ""
                let connection = SSEConnection(
                    url: sseUrl,
                    token: currentToken,
                    options: SSEConnectionOptions(
                        onEvent: { event in continuation.yield(event) },
                        onError: { error in continuation.finish(throwing: error) }
                    )
                )
                continuation.onTermination = { _ in connection.close() }
            }
        }
    }
}
