import Foundation

public enum ActorType: String, Codable, Sendable {
    case bridge
    case camera
    case speaker
    case account
    case user
    case layout
    case job
    case measurement
    case sensor
    case gateway
}

public struct EventData: Codable, Sendable {
    public let type: String
    public let creatorId: String
    /// Additional polymorphic properties from the event data.
    public let additionalProperties: [String: AnyCodable]?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var type: String?
        var creatorId: String?
        var extra: [String: AnyCodable] = [:]

        for key in container.allKeys {
            switch key.stringValue {
            case "type": type = try container.decode(String.self, forKey: key)
            case "creatorId": creatorId = try container.decode(String.self, forKey: key)
            default: extra[key.stringValue] = try container.decode(AnyCodable.self, forKey: key)
            }
        }

        self.type = type ?? ""
        self.creatorId = creatorId ?? ""
        self.additionalProperties = extra.isEmpty ? nil : extra
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encode(type, forKey: DynamicCodingKey(stringValue: "type"))
        try container.encode(creatorId, forKey: DynamicCodingKey(stringValue: "creatorId"))
        if let extra = additionalProperties {
            for (key, value) in extra {
                try container.encode(value, forKey: DynamicCodingKey(stringValue: key))
            }
        }
    }
}

public struct Event: Codable, Identifiable, Sendable {
    public let id: String
    public let startTimestamp: String
    public let endTimestamp: String?
    public let span: Bool
    public let accountId: String
    public let actorId: String
    public let actorAccountId: String
    public let actorType: ActorType
    public let creatorId: String
    public let type: String
    public let dataSchemas: [String]
    public let data: [EventData]
}

public struct EventType: Codable, Sendable {
    public let type: String
    public let name: String
    public let description: String
}

public struct EventFieldValues: Codable, Sendable {
    public let type: [String]
}

public struct ListEventsParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var actor: String
    public var typeIn: [String]
    public var startTimestampGte: String
    public var startTimestampLte: String?
    public var endTimestampGte: String?
    public var endTimestampLte: String?
    public var sort: String?
    public var include: [String]?

    public init(actor: String, typeIn: [String], startTimestampGte: String,
                pageSize: Int? = nil, pageToken: String? = nil) {
        self.actor = actor
        self.typeIn = typeIn
        self.startTimestampGte = startTimestampGte
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.add("actor", actor)
        b.addIn("type", typeIn)
        b.addGte("startTimestamp", startTimestampGte)
        b.addLte("startTimestamp", startTimestampLte)
        b.addGte("endTimestamp", endTimestampGte)
        b.addLte("endTimestamp", endTimestampLte)
        b.add("sort", sort)
        b.addInclude(include)
        return b.items
    }
}

public struct ListEventTypesParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var language: String?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.add("language", language)
        return b.items
    }
}

public struct ListEventFieldValuesParams: Sendable {
    public var actor: String
    public init(actor: String) { self.actor = actor }
}

// MARK: - Dynamic coding support

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

/// Type-erased Codable wrapper for heterogeneous JSON values.
public enum AnyCodable: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { self = .bool(v) }
        else if let v = try? container.decode(Int.self) { self = .int(v) }
        else if let v = try? container.decode(Double.self) { self = .double(v) }
        else if let v = try? container.decode(String.self) { self = .string(v) }
        else if container.decodeNil() { self = .null }
        else { self = .null }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}
