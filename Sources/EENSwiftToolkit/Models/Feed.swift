import Foundation

public enum FeedStreamType: String, Codable, Sendable {
    case main
    case preview
    case talkdown
}

public enum FeedMediaType: String, Codable, Sendable {
    case video
    case audio
    case image
    case halfDuplex
    case fullDuplex
}

public struct Feed: Codable, Identifiable, Sendable {
    public let id: String
    public let type: FeedStreamType
    public let deviceId: String
    public let mediaType: FeedMediaType
    public let flvUrl: String?
    public let rtspUrl: String?
    public let rtspsUrl: String?
    public let localRtspUrl: String?
    public let hlsUrl: String?
    public let multipartUrl: String?
    public let webRtcUrl: String?
    public let audioPushHttpsUrl: String?
}

public struct ListFeedsParams: Sendable, QueryParamEncodable {
    public var deviceId: String?
    public var deviceIdIn: [String]?
    public var type: FeedStreamType?
    public var include: [String]?
    public var pageSize: Int?
    public var pageToken: String?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.add("deviceId", deviceId)
        b.addIn("deviceId", deviceIdIn)
        if let type { b.add("type", type.rawValue) }
        b.addInclude(include)
        return b.items
    }
}
