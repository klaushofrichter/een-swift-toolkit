import Foundation

public struct HumanValidation: Codable, Sendable {
    public let required: Bool
    public let timeoutSeconds: Int?
}

public struct EventResourceFilter: Codable, Sendable {
    public let accountIds: [String]?
    public let actorIds: [String]?
    public let actorTagsContains: [String]?
    public let actorTagsAny: [String]?

    enum CodingKeys: String, CodingKey {
        case accountIds, actorIds
        case actorTagsContains = "actorTags__contains"
        case actorTagsAny = "actorTags__any"
    }
}

public struct EventFilter: Codable, Sendable {
    public let types: [String]
    public let resourceFilter: EventResourceFilter?
}

public struct EventAlertConditionRule: Codable, Identifiable, Sendable {
    public let id: String
    public let createTimestamp: String
    public let updateTimestamp: String
    public let name: String
    public let priority: Int
    public let notes: String?
    public let enabled: Bool
    public let cooldownSeconds: Int
    public let humanValidation: HumanValidation?
    public let eventFilter: EventFilter
    public let outputAlertTypes: [String]
}

public struct EventAlertConditionRuleFieldValues: Codable, Sendable {
    public let eventTypes: [String]?
    public let outputAlertTypes: [String]?
}

public struct AlertConditionRuleActor: Codable, Sendable {
    public let id: String
    public let type: String
    public let accountId: String?
}

public struct AlertConditionRuleAction: Codable, Sendable {
    public let id: String
    public let name: String?
    public let type: String?
}

public struct AlertConditionRuleInsights: Codable, Sendable {
    public let totalAlerts: Int?
    public let lastTriggered: String?
    public let alertCounts: AlertCounts?

    public struct AlertCounts: Codable, Sendable {
        public let last24Hours: Int?
        public let last7Days: Int?
        public let last30Days: Int?
    }
}

public struct AlertConditionRule: Codable, Identifiable, Sendable {
    public let id: String
    public let createTimestamp: String
    public let type: String
    public let creatorId: String
    public let name: String
    public let notes: String?
    public let enabled: Bool
    public let priority: Int
    public let actors: [AlertConditionRuleActor]
    public let inputEventTypes: [String]
    public let outputAlertType: String
    public let actions: [AlertConditionRuleAction]?
    public let insights: AlertConditionRuleInsights?
}

public struct AlertActionRule: Codable, Identifiable, Sendable {
    public let id: String
    public let createTimestamp: String
    public let name: String
    public let notes: String?
    public let enabled: Bool
    public let alertTypes: [String]
    public let actorIds: [String]
    public let actorTypes: [String]
    public let ruleIds: [String]
    public let alertActionIds: [String]
}

public enum AlertActionType: String, Codable, Sendable {
    case notification, sms, smtp, slack, webhook
    case brivo, zendesk, immix, zapier, sentinel
    case evalinkTalos, outputPort, ebus
    case playSpeakerAudioClip
    case zulipPrivate, zulipStream
}

public struct AutomationAlertAction: Codable, Identifiable, Sendable {
    public let id: String
    public let createTimestamp: String
    public let type: AlertActionType
    public let name: String
    public let notes: String?
    public let enabled: Bool
}

// MARK: - List Params

public struct ListEventAlertConditionRulesParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var enabled: Bool?
    public var idIn: [String]?
    public var outputAlertTypeIn: [String]?
    public var priorityGte: Int?
    public var priorityLte: Int?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.add("enabled", enabled)
        b.addIn("id", idIn)
        b.addIn("outputAlertType", outputAlertTypeIn)
        b.addGte("priority", priorityGte)
        b.addLte("priority", priorityLte)
        return b.items
    }
}

public struct ListAlertConditionRulesParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var enabled: Bool?
    public var idIn: [String]?
    public var actorIdIn: [String]?
    public var inputEventTypeIn: [String]?
    public var outputAlertType: String?
    public var type: String?
    public var include: [String]?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.add("enabled", enabled)
        b.addIn("id", idIn)
        b.addIn("actorId", actorIdIn)
        b.addIn("inputEventType", inputEventTypeIn)
        b.add("outputAlertType", outputAlertType)
        b.add("type", type)
        b.addInclude(include)
        return b.items
    }
}

public struct ListAlertActionRulesParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var enabled: Bool?
    public var idIn: [String]?
    public var alertTypeIn: [String]?
    public var actorIdIn: [String]?
    public var alertActionIdIn: [String]?
    public var ruleIdIn: [String]?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.add("enabled", enabled)
        b.addIn("id", idIn)
        b.addIn("alertType", alertTypeIn)
        b.addIn("actorId", actorIdIn)
        b.addIn("alertActionId", alertActionIdIn)
        b.addIn("ruleId", ruleIdIn)
        return b.items
    }
}

public struct ListAlertActionsParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var enabled: Bool?
    public var idIn: [String]?
    public var typeIn: [AlertActionType]?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.add("enabled", enabled)
        b.addIn("id", idIn)
        if let typeIn { b.addIn("type", typeIn.map(\.rawValue)) }
        return b.items
    }
}
