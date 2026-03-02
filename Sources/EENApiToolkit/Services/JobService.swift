import Foundation

/// Service for Job and Export API endpoints.
public struct JobService: Sendable {
    let client: HTTPClient

    /// List jobs with optional filters.
    public func list(params: ListJobsParams = .init()) async throws -> PaginatedResult<Job> {
        try await client.request(Endpoint(path: "/api/v3.0/jobs", queryItems: params.toQueryItems()))
    }

    /// Get a single job by ID.
    public func get(id: String, include: [String]? = nil) async throws -> Job {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/jobs/\(id)", queryItems: queryItems))
    }

    /// Delete a job.
    public func delete(id: String) async throws {
        try await client.requestVoid(Endpoint(method: .delete, path: "/api/v3.0/jobs/\(id)"))
    }

    /// Create an export job.
    public func createExport(params: CreateExportParams) async throws -> ExportJobResponse {
        try await client.request(Endpoint(method: .post, path: "/api/v3.0/exports", body: params))
    }
}
