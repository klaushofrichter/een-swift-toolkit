import Foundation

/// Service for File API endpoints.
public struct FileService: Sendable {
    let client: HTTPClient

    /// List files with optional filters.
    public func list(params: ListFilesParams = .init()) async throws -> PaginatedResult<EenFile> {
        try await client.request(Endpoint(path: "/api/v3.0/files", queryItems: params.toQueryItems()))
    }

    /// Get file metadata by ID.
    public func get(id: String, include: [String]? = nil) async throws -> EenFile {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/files/\(id)", queryItems: queryItems))
    }

    /// Create a new file entry.
    public func add(params: CreateFileParams) async throws -> EenFile {
        try await client.request(Endpoint(method: .post, path: "/api/v3.0/files", body: params))
    }

    /// Download a file's contents.
    public func download(id: String) async throws -> Data {
        try await client.requestData(Endpoint(path: "/api/v3.0/files/\(id)/content"))
    }

    /// Delete a file.
    public func delete(id: String) async throws {
        try await client.requestVoid(Endpoint(method: .delete, path: "/api/v3.0/files/\(id)"))
    }
}
