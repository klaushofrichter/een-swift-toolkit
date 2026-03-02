import Foundation

public enum FileType: String, Codable, Sendable {
    case export
    case upload
    case snapshot
    case other
}

public struct EenFile: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let mimeType: String?
    public let directory: String?
    public let accountId: String?
    public let notes: String?
    public let createTimestamp: String?
    public let updateTimestamp: String?
    public let size: Int?
    public let tags: [String]?
    public let childCount: Int?
    public let filename: String?
    public let contentType: String?
    public let type: FileType?
    public let jobId: String?
    public let cameraId: String?
    public let description: String?
    public let expirationTimestamp: String?
}

public struct ListFilesParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var include: [String]?
    public var typeIn: [FileType]?
    public var cameraId: String?
    public var cameraIdIn: [String]?
    public var jobId: String?
    public var createTimestampGte: String?
    public var createTimestampLte: String?
    public var tagsContains: [String]?
    public var q: String?
    public var sort: [String]?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.addInclude(include)
        if let typeIn { b.addIn("type", typeIn.map(\.rawValue)) }
        b.add("cameraId", cameraId)
        b.addIn("cameraId", cameraIdIn)
        b.add("jobId", jobId)
        b.addGte("createTimestamp", createTimestampGte)
        b.addLte("createTimestamp", createTimestampLte)
        b.addContains("tags", tagsContains)
        b.add("q", q)
        b.addSort(sort)
        return b.items
    }
}

public struct CreateFileParams: Codable, Sendable {
    public let name: String
    public let type: FileType?
    public let filename: String?
    public let description: String?
    public let tags: [String]?
    public let cameraId: String?

    public init(name: String, type: FileType? = nil, filename: String? = nil,
                description: String? = nil, tags: [String]? = nil, cameraId: String? = nil) {
        self.name = name
        self.type = type
        self.filename = filename
        self.description = description
        self.tags = tags
        self.cameraId = cameraId
    }
}

public struct DownloadFileResult: Sendable {
    public let data: Data
    public let filename: String
    public let contentType: String
    public let size: Int
}
