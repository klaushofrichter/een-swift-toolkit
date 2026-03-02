import Foundation

public enum BridgeStatus: String, Codable, Sendable {
    case online
    case offline
    case error
    case idle
    case registered
    case attaching
    case initializing
}

public struct BridgeDeviceInfo: Codable, Sendable {
    public let make: String?
    public let model: String?
    public let firmwareVersion: String?
    public let serialNumber: String?
    public let hardwareVersion: String?
}

public struct BridgeNetworkInfo: Codable, Sendable {
    public let localIpAddress: String?
    public let publicIpAddress: String?
    public let macAddress: String?
    public let subnetMask: String?
    public let gateway: String?
    public let dnsServers: [String]?
}

public struct BridgeDevicePosition: Codable, Sendable {
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let floor: Int?
    public let azimuth: Double?
}

public enum BridgeStatusValue: Codable, Sendable {
    case status(BridgeStatus)
    case statusObject(connectionStatus: BridgeStatus?)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self), let status = BridgeStatus(rawValue: str) {
            self = .status(status)
        } else {
            let obj = try BridgeStatusObject(from: decoder)
            self = .statusObject(connectionStatus: obj.connectionStatus)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .status(let s):
            var container = encoder.singleValueContainer()
            try container.encode(s)
        case .statusObject(let cs):
            try BridgeStatusObject(connectionStatus: cs).encode(to: encoder)
        }
    }

    public var effectiveStatus: BridgeStatus? {
        switch self {
        case .status(let s): return s
        case .statusObject(let cs): return cs
        }
    }
}

private struct BridgeStatusObject: Codable, Sendable {
    let connectionStatus: BridgeStatus?
}

public struct Bridge: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let accountId: String
    public let locationId: String?
    public let guid: String?
    public let timezone: String?
    public let status: BridgeStatusValue?
    public let tags: [String]?
    public let deviceInfo: BridgeDeviceInfo?
    public let networkInfo: BridgeNetworkInfo?
    public let devicePosition: BridgeDevicePosition?
    public let cameraCount: Int?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct ListBridgesParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var include: [String]?
    public var sort: [String]?
    public var locationIdIn: [String]?
    public var tagsContains: [String]?
    public var tagsAny: [String]?
    public var name: String?
    public var nameContains: String?
    public var nameIn: [String]?
    public var idIn: [String]?
    public var idNotIn: [String]?
    public var q: String?
    public var qRelevanceGte: Double?
    public var statusIn: [BridgeStatus]?
    public var statusNe: BridgeStatus?

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
        b.addContains("tags", tagsContains)
        b.addAny("tags", tagsAny)
        b.add("name", name)
        b.add("name__contains", nameContains)
        b.addIn("name", nameIn)
        b.addIn("id", idIn)
        b.addIn("id__notIn", idNotIn)
        b.add("q", q)
        b.addGte("qRelevance", qRelevanceGte)
        if let statusIn { b.addIn("status", statusIn.map(\.rawValue)) }
        if let statusNe { b.addNe("status", statusNe.rawValue) }
        return b.items
    }
}
