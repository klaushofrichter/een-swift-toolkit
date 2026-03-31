import Foundation

public enum MediaType: String, Codable, Sendable {
    case video
    case image
}

public enum MediaStreamType: String, Codable, Sendable {
    case preview
    case main
}

public struct MediaInterval: Codable, Sendable {
    public let type: MediaStreamType
    public let deviceId: String
    public let mediaType: MediaType
    public let startTimestamp: String
    public let endTimestamp: String
    public let flvUrl: String?
    public let rtspUrl: String?
    public let rtspsUrl: String?
    public let hlsUrl: String?
    public let multipartUrl: String?
    public let mp4Url: String?
    public let wsLiveUrl: String?
}

public struct ListMediaParams: Sendable, QueryParamEncodable {
    public var deviceId: String
    public var type: MediaStreamType
    public var mediaType: MediaType
    public var startTimestamp: String
    public var endTimestamp: String?
    public var coalesce: Bool?
    public var include: [String]?
    public var pageToken: String?
    public var pageSize: Int?

    public init(deviceId: String, type: MediaStreamType, mediaType: MediaType, startTimestamp: String) {
        self.deviceId = deviceId
        self.type = type
        self.mediaType = mediaType
        self.startTimestamp = startTimestamp
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.add("type", type.rawValue)
        b.add("mediaType", mediaType.rawValue)
        b.addGte("startTimestamp", startTimestamp)
        b.addLte("endTimestamp", endTimestamp)
        b.add("coalesce", coalesce)
        b.addInclude(include)
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        return b.items
    }
}

public struct LiveImageResult: Sendable {
    /// Base64-encoded image data.
    public let imageData: Data
    /// Content type of the image (e.g., "image/jpeg").
    public let contentType: String
    public let timestamp: String?
    public let prevToken: String?
}

public struct RecordedImageResult: Sendable {
    /// Base64-encoded image data.
    public let imageData: Data
    /// Content type of the image.
    public let contentType: String
    public let timestamp: String?
    public let nextToken: String?
    public let prevToken: String?
}

public struct GetLiveImageParams: Sendable {
    public var deviceId: String
    public var type: String?

    public init(deviceId: String, type: String? = "preview") {
        self.deviceId = deviceId
        self.type = type
    }
}

public struct GetRecordedImageParams: Sendable, QueryParamEncodable {
    public var deviceId: String?
    public var pageToken: String?
    public var type: MediaStreamType?
    public var timestampLt: String?
    public var timestampLte: String?
    public var timestamp: String?
    public var timestampGte: String?
    public var timestampGt: String?
    public var overlayIdIn: [String]?
    public var include: [String]?
    public var targetWidth: Int?
    public var targetHeight: Int?

    public init() {}

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.add("pageToken", pageToken)
        if let type { b.add("type", type.rawValue) }
        b.add("timestamp__lt", timestampLt)
        b.add("timestamp__lte", timestampLte)
        b.add("timestamp", timestamp)
        b.add("timestamp__gte", timestampGte)
        b.add("timestamp__gt", timestampGt)
        b.addIn("overlayId", overlayIdIn)
        b.addInclude(include)
        b.add("targetWidth", targetWidth)
        b.add("targetHeight", targetHeight)
        return b.items
    }
}

public struct MediaSessionResponse: Codable, Sendable {
    public let url: String
}
