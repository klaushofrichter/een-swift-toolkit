import Foundation

public enum AlertActionStatus: String, Codable, Sendable {
    case fired
    case success
    case partialSuccess
    case silenced
    case failed
    case internalError
}

public struct AlertAction: Codable, Sendable {
    public let name: String
    public let type: String
    public let success: Bool
    public let timestamp: String
    public let status: AlertActionStatus?
}

public struct Alert: Codable, Identifiable, Sendable {
    public let id: String
    public let timestamp: String
    public let createTimestamp: String
    public let creatorId: String
    public let alertType: String
    public let alertName: String?
    public let category: String?
    public let serviceRuleId: String?
    public let eventType: String?
    public let actorId: String
    public let actorType: String
    public let actorAccountId: String
    public let actorName: String?
    public let ruleId: String?
    public let eventId: String?
    public let locationId: String?
    public let locationName: String?
    public let priority: Int?
    public let dataSchemas: [String]?
    public let data: [String: AnyCodable]?
    public let actions: [String: AlertAction]?
    public let description: String?
}

public struct AlertType: Codable, Sendable {
    public let type: String
    public let description: String
}

public struct ListAlertsParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var timestampLte: String?
    public var timestampGte: String?
    public var creatorId: String?
    public var alertTypeIn: [String]?
    public var actorIdIn: [String]?
    public var actorTypeIn: [String]?
    public var actorAccountId: String?
    public var ruleId: String?
    public var ruleIdIn: [String]?
    public var eventId: String?
    public var locationIdIn: [String]?
    public var priorityGte: Int?
    public var priorityLte: Int?
    public var showInvalidAlerts: Bool?
    public var alertActionIdIn: [String]?
    public var alertActionStatusIn: [AlertActionStatus]?
    public var include: [String]?
    public var sort: [String]?
    public var language: String?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.addLte("timestamp", timestampLte)
        b.addGte("timestamp", timestampGte)
        b.add("creatorId", creatorId)
        b.addIn("alertType", alertTypeIn)
        b.addIn("actorId", actorIdIn)
        b.addIn("actorType", actorTypeIn)
        b.add("actorAccountId", actorAccountId)
        b.add("ruleId", ruleId)
        b.addIn("ruleId", ruleIdIn)
        b.add("eventId", eventId)
        b.addIn("locationId", locationIdIn)
        b.addGte("priority", priorityGte)
        b.addLte("priority", priorityLte)
        b.add("showInvalidAlerts", showInvalidAlerts)
        b.addIn("alertActionId", alertActionIdIn)
        if let alertActionStatusIn {
            b.addIn("alertActionStatus", alertActionStatusIn.map(\.rawValue))
        }
        b.addInclude(include)
        b.addSort(sort)
        b.add("language", language)
        return b.items
    }
}

public struct ListAlertTypesParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        return b.items
    }
}
