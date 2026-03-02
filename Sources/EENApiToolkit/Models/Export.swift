import Foundation

public enum ExportType: String, Codable, Sendable {
    case bundle
    case timeLapse
    case video
}

public struct CreateExportParams: Codable, Sendable {
    public let name: String?
    public let type: ExportType
    public let cameraId: String
    public let startTimestamp: String
    public let endTimestamp: String
    public let playbackMultiplier: Int?
    public let autoDelete: Bool?
    public let directory: String?
    public let notes: String?
    public let tags: [String]?

    public init(
        type: ExportType, cameraId: String, startTimestamp: String, endTimestamp: String,
        name: String? = nil, playbackMultiplier: Int? = nil, autoDelete: Bool? = nil,
        directory: String? = nil, notes: String? = nil, tags: [String]? = nil
    ) {
        self.type = type
        self.cameraId = cameraId
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.name = name
        self.playbackMultiplier = playbackMultiplier
        self.autoDelete = autoDelete
        self.directory = directory
        self.notes = notes
        self.tags = tags
    }
}

/// Export job response is the same as a Job.
public typealias ExportJobResponse = Job
