import Foundation

public enum JobState: String, Codable, Sendable {
    case pending
    case started
    case success
    case failure
    case revoked
}

public struct JobResultFile: Codable, Sendable {
    public let name: String
    public let path: String?
    public let size: Int?
    public let startTimestamp: String?
    public let endTimestamp: String?
    public let url: String?
    public let checksum: String?
}

public struct JobResultInterval: Codable, Sendable {
    public let startTimestamp: String?
    public let endTimestamp: String?
    public let state: String?
    public let files: [JobResultFile]?
    public let error: String?
}

public struct JobResult: Codable, Sendable {
    public let state: String?
    public let error: String?
    public let intervals: [JobResultInterval]?
}

public struct JobOriginalRequest: Codable, Sendable {
    public let type: String?
    public let name: String?
    public let directory: String?
    public let startTimestamp: String?
    public let endTimestamp: String?
    public let notes: String?
    public let tags: [String]?
}

public struct JobArguments: Codable, Sendable {
    public let deviceId: String?
    public let originalRequest: JobOriginalRequest?
}

public struct Job: Codable, Identifiable, Sendable {
    public let id: String
    public let namespace: String?
    public let type: String
    public let userId: String
    public let state: JobState
    public let detailedState: String?
    public let progress: Double?
    public let error: String?
    public let arguments: JobArguments?
    public let result: JobResult?
    public let createTimestamp: String
    public let updateTimestamp: String?
    public let expireTimestamp: String?
    public let scheduleTimestamp: String?
}

public struct ListJobsParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var stateIn: [JobState]?
    public var type: String?
    public var typeIn: [String]?
    public var createTimestampGte: String?
    public var createTimestampLte: String?
    public var userId: String?
    public var sort: [String]?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        if let stateIn { b.addIn("state", stateIn.map(\.rawValue)) }
        b.add("type", type)
        b.addIn("type", typeIn)
        b.addGte("createTimestamp", createTimestampGte)
        b.addLte("createTimestamp", createTimestampLte)
        b.add("userId", userId)
        b.addSort(sort)
        return b.items
    }
}
