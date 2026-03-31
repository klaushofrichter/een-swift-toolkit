import Foundation

/// Service for PTZ (Pan-Tilt-Zoom) API endpoints.
public struct PTZService: Sendable {
    let client: HTTPClient

    /// Get the current PTZ position of a camera.
    public func getPosition(cameraId: String) async throws -> PtzPositionResponse {
        try await client.request(Endpoint(path: "/api/v3.0/cameras/\(cameraId)/ptz/position"))
    }

    /// Move the PTZ camera.
    public func move(cameraId: String, move: PtzMove) async throws {
        try await client.requestVoid(Endpoint(
            method: .put,
            path: "/api/v3.0/cameras/\(cameraId)/ptz/position",
            body: move
        ))
    }

    /// Get PTZ settings for a camera.
    public func getSettings(cameraId: String) async throws -> PtzSettings {
        try await client.request(Endpoint(path: "/api/v3.0/cameras/\(cameraId)/ptz/settings"))
    }

    /// Update PTZ settings for a camera.
    public func updateSettings(cameraId: String, settings: PtzSettingsUpdate) async throws -> PtzSettings {
        try await client.request(Endpoint(
            method: .put,
            path: "/api/v3.0/cameras/\(cameraId)/ptz/settings",
            body: settings
        ))
    }
}
