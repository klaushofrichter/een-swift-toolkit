import Foundation

/// Service for Download API endpoints.
public struct DownloadService: Sendable {
    let client: HTTPClient

    /// List downloads with optional filters.
    public func list(params: ListDownloadsParams = .init()) async throws -> PaginatedResult<Download> {
        try await client.request(Endpoint(path: "/api/v3.0/downloads", queryItems: params.toQueryItems()))
    }

    /// Get a single download by ID.
    public func get(id: String, include: [String]? = nil) async throws -> Download {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/downloads/\(id)", queryItems: queryItems))
    }

    /// Download the content of a download entry.
    public func downloadContent(id: String) async throws -> Data {
        try await client.requestData(Endpoint(path: "/api/v3.0/downloads/\(id)/content"))
    }
}
