import Foundation

/// Service for Media API endpoints (recording intervals, live/recorded images).
public struct MediaService: Sendable {
    let client: HTTPClient

    /// List recording intervals for a device.
    public func listMedia(params: ListMediaParams) async throws -> PaginatedResult<MediaInterval> {
        var queryItems = params.toQueryItems()
        queryItems.append(URLQueryItem(name: "deviceId", value: params.deviceId))
        let result: PaginatedResult<MediaInterval> = try await client.request(Endpoint(
            path: "/api/v3.0/media",
            queryItems: queryItems
        ))
        return result
    }

    /// Get a live preview image from a camera. Returns raw image data.
    public func getLiveImage(params: GetLiveImageParams) async throws -> LiveImageResult {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "deviceId", value: params.deviceId)
        ]
        if let type = params.type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }

        let endpoint = Endpoint(
            path: "/api/v3.0/media/liveImage.jpeg",
            queryItems: queryItems,
            additionalHeaders: ["Accept": "image/jpeg"]
        )

        let data = try await client.requestData(endpoint)
        return LiveImageResult(imageData: data, contentType: "image/jpeg", timestamp: nil, prevToken: nil)
    }

    /// Get a recorded image from a camera. Returns raw image data.
    public func getRecordedImage(deviceId: String, params: GetRecordedImageParams = .init()) async throws -> RecordedImageResult {
        var queryItems = params.toQueryItems()
        queryItems.append(URLQueryItem(name: "deviceId", value: deviceId))

        let endpoint = Endpoint(
            path: "/api/v3.0/media/recordedImage.jpeg",
            queryItems: queryItems,
            additionalHeaders: ["Accept": "image/jpeg"]
        )

        let data = try await client.requestData(endpoint)
        return RecordedImageResult(imageData: data, contentType: "image/jpeg", timestamp: nil, nextToken: nil, prevToken: nil)
    }

    /// Get a media session URL.
    public func getMediaSession(deviceId: String) async throws -> MediaSessionResponse {
        try await client.request(Endpoint(path: "/api/v3.0/media/session"))
    }

    /// Initialize a media session.
    public func initMediaSession(deviceId: String) async throws -> MediaSessionResponse {
        try await client.request(Endpoint(method: .post, path: "/api/v3.0/media/session"))
    }
}
