import Foundation

public enum CameraStatus: String, Codable, Sendable {
    case online
    case offline
    case deviceOffline
    case bridgeOffline
    case invalidCredentials
    case error
    case streaming
    case registered
    case attaching
    case initializing
}

public struct CameraDeviceInfo: Codable, Sendable {
    public let make: String?
    public let model: String?
    public let firmwareVersion: String?
    public let directToCloud: Bool?
    public let serialNumber: String?
    public let resolution: String?
    public let type: String?
}

public struct CameraShareDetails: Codable, Sendable {
    public let shared: Bool?
    public let accountId: String?
    public let firstResponder: Bool?
    public let permissions: [String]?
}

public struct CameraStreamUrls: Codable, Sendable {
    public let hls: String?
    public let rtsp: String?
    public let webrtc: String?
    public let jpeg: String?
}

public struct CameraRtspConnectionSettings: Codable, Sendable {
    public let url: String?
    public let username: String?
    public let password: String?
    public let transport: String?
}

public struct CameraDevicePosition: Codable, Sendable {
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let floor: Int?
    public let azimuth: Double?
}

public struct CameraRecordingModes: Codable, Sendable {
    public let continuous: Bool?
    public let motion: Bool?
    public let scheduled: Bool?
}

public struct CameraPtzCapabilities: Codable, Sendable {
    public let capable: Bool?
    public let fisheye: Bool?
    public let panTilt: Bool?
    public let zoom: Bool?
    public let positionMove: Bool?
    public let directionMove: Bool?
    public let centerOnMove: Bool?
}

public struct CameraCapabilities: Codable, Sendable {
    public let ptz: CameraPtzCapabilities?
}

/// The `status` field can be either a plain string or an object with `connectionStatus`.
public enum CameraStatusValue: Codable, Sendable {
    case status(CameraStatus)
    case statusObject(connectionStatus: CameraStatus?)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self), let status = CameraStatus(rawValue: str) {
            self = .status(status)
        } else {
            let obj = try CameraStatusObject(from: decoder)
            self = .statusObject(connectionStatus: obj.connectionStatus)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .status(let s):
            var container = encoder.singleValueContainer()
            try container.encode(s)
        case .statusObject(let cs):
            try CameraStatusObject(connectionStatus: cs).encode(to: encoder)
        }
    }

    /// Get the effective status regardless of the representation.
    public var effectiveStatus: CameraStatus? {
        switch self {
        case .status(let s): return s
        case .statusObject(let cs): return cs
        }
    }
}

private struct CameraStatusObject: Codable, Sendable {
    let connectionStatus: CameraStatus?
}

public struct Camera: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let accountId: String
    public let bridgeId: String?
    public let locationId: String?
    public let guid: String?
    public let macAddress: String?
    public let ipAddress: String?
    public let timezone: String?
    public let status: CameraStatusValue?
    public let tags: [String]?
    public let packages: [String]?
    public let multiCameraId: String?
    public let speakerId: String?
    public let deviceInfo: CameraDeviceInfo?
    public let shareDetails: CameraShareDetails?
    public let streamUrls: CameraStreamUrls?
    public let rtspConnectionSettings: CameraRtspConnectionSettings?
    public let devicePosition: CameraDevicePosition?
    public let capabilities: CameraCapabilities?
    public let enabledAnalytics: [String]?
    public let recordingModes: CameraRecordingModes?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct ListCamerasParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var include: [String]?
    public var sort: [String]?
    public var locationIdIn: [String]?
    public var bridgeIdIn: [String]?
    public var multiCameraId: String?
    public var multiCameraIdNe: String?
    public var multiCameraIdIn: [String]?
    public var tagsContains: [String]?
    public var tagsAny: [String]?
    public var packagesContains: [String]?
    public var name: String?
    public var nameContains: String?
    public var nameIn: [String]?
    public var idIn: [String]?
    public var idNotIn: [String]?
    public var idContains: String?
    public var layoutId: String?
    public var shared: Bool?
    public var sharedCameraAccount: String?
    public var firstResponder: Bool?
    public var directToCloud: Bool?
    public var speakerIdIn: [String]?
    public var q: String?
    public var qRelevanceGte: Double?
    public var enabledAnalyticsContains: [String]?
    public var statusIn: [CameraStatus]?
    public var statusNe: CameraStatus?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.addInclude(include)
        b.addSort(sort)
        b.addIn("locationId", locationIdIn)
        b.addIn("bridgeId", bridgeIdIn)
        b.add("multiCameraId", multiCameraId)
        b.addNe("multiCameraId", multiCameraIdNe)
        b.addIn("multiCameraId", multiCameraIdIn)
        b.addContains("tags", tagsContains)
        b.addAny("tags", tagsAny)
        b.addContains("packages", packagesContains)
        b.add("name", name)
        b.add("name__contains", nameContains)
        b.addIn("name", nameIn)
        b.addIn("id", idIn)
        b.addIn("id__notIn", idNotIn)
        b.add("id__contains", idContains)
        b.add("layoutId", layoutId)
        b.add("shared", shared)
        b.add("sharedCameraAccount", sharedCameraAccount)
        b.add("firstResponder", firstResponder)
        b.add("directToCloud", directToCloud)
        b.addIn("speakerId", speakerIdIn)
        b.add("q", q)
        b.addGte("qRelevance", qRelevanceGte)
        b.addContains("enabledAnalytics", enabledAnalyticsContains)
        if let statusIn {
            b.addIn("status", statusIn.map(\.rawValue))
        }
        if let statusNe {
            b.addNe("status", statusNe.rawValue)
        }
        return b.items
    }
}

public enum CameraSettingsInclude: String, Sendable {
    case schema
    case proposedValues
}

public struct GetCameraSettingsParams: Sendable {
    public var include: [CameraSettingsInclude]?
    public init(include: [CameraSettingsInclude]? = nil) { self.include = include }
}

public struct CameraSettingsRetention: Codable, Sendable {
    public let cloudDays: Int?
    public let cloudPreviewOnly: Bool?
    public let minimumOnPremiseDays: Int?
    public let maximumOnPremiseDays: Int?
    public let alwaysRecordingDays: Int?
}

public struct CameraSettingsAudio: Codable, Sendable {
    public let microphoneEnabled: Bool?
    public let inputSourceId: String?
}

public struct CameraSettingsPreviewVideo: Codable, Sendable {
    public let transmitMode: String?
    public let resolution: String?
    public let intervalMs: Int?
    public let quality: String?
    public let supportedResolutions: [String]?
}

public struct CameraSettingsMainVideo: Codable, Sendable {
    public let transmitMode: String?
    public let resolution: String?
    public let quality: String?
    public let kbpsFactor: Double?
    public let captureMode: String?
    public let supportedResolutions: [String]?
}

public struct CameraSettingsAnalog: Codable, Sendable {
    public let videoStandard: String?
    public let badSignalProtection: Bool?
    public let badSignalDetected: Bool?
}

public struct CameraSettingsScheduledOverride: Codable, Sendable {
    public let on: Bool?
    public let schedule: String?
}

public struct CameraSettingsOperating: Codable, Sendable {
    public let on: Bool?
    public let scheduledOverride: CameraSettingsScheduledOverride?
}

public struct CameraSettingsTalkdown: Codable, Sendable {
    public let `protocol`: String?
    public let audioMode: String?
}

public struct CameraSettingsCredentials: Codable, Sendable {
    public let username: String?
    public let password: String?
}

public struct CameraSettingsData: Codable, Sendable {
    public let timeZone: String?
    public let rtsp: CameraRtspConnectionSettings?
    public let credentials: CameraSettingsCredentials?
    public let retention: CameraSettingsRetention?
    public let audio: CameraSettingsAudio?
    public let previewVideo: CameraSettingsPreviewVideo?
    public let mainVideo: CameraSettingsMainVideo?
    public let analog: CameraSettingsAnalog?
    public let operatingSettings: CameraSettingsOperating?
    public let talkdown: CameraSettingsTalkdown?
}

public struct CameraSettings: Codable, Sendable {
    public let data: CameraSettingsData
}
