import Foundation

public enum DownloadStatus: String, Codable, Sendable {
    case available
    case expired
    case pending
    case error
}

public struct Download: Codable, Identifiable, Sendable {
    public let id: String
    public let accountId: String
    public let name: String
    public let status: DownloadStatus
    public let contentType: String?
    public let sizeBytes: Int?
    public let fileId: String?
    public let jobId: String?
    public let cameraId: String?
    public let description: String?
    public let createTimestamp: String
    public let expirationTimestamp: String?
    public let downloadUrl: String?
}

public struct ListDownloadsParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var statusIn: [DownloadStatus]?
    public var cameraId: String?
    public var cameraIdIn: [String]?
    public var jobId: String?
    public var fileId: String?
    public var createTimestampGte: String?
    public var createTimestampLte: String?
    public var q: String?
    public var sort: [String]?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        if let statusIn { b.addIn("status", statusIn.map(\.rawValue)) }
        b.add("cameraId", cameraId)
        b.addIn("cameraId", cameraIdIn)
        b.add("jobId", jobId)
        b.add("fileId", fileId)
        b.addGte("createTimestamp", createTimestampGte)
        b.addLte("createTimestamp", createTimestampLte)
        b.add("q", q)
        b.addSort(sort)
        return b.items
    }
}
