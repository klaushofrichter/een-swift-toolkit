import Foundation

/// Service for Camera API endpoints.
public struct CameraService: Sendable {
    let client: HTTPClient

    /// List cameras with optional filters.
    public func list(params: ListCamerasParams = .init()) async throws -> PaginatedResult<Camera> {
        try await client.request(Endpoint(path: "/api/v3.0/cameras", queryItems: params.toQueryItems()))
    }

    /// Get a single camera by ID.
    public func get(id: String, include: [String]? = nil) async throws -> Camera {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/cameras/\(id)", queryItems: queryItems))
    }

    /// Get camera operational settings.
    public func getSettings(cameraId: String, params: GetCameraSettingsParams = .init()) async throws -> CameraSettings {
        var queryItems: [URLQueryItem] = []
        if let include = params.include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.map(\.rawValue).joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/cameras/\(cameraId)/settings", queryItems: queryItems))
    }
}
