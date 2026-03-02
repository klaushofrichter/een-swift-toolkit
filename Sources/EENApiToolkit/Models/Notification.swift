import Foundation

public enum NotificationCategory: String, Codable, Sendable {
    case health
    case video
    case operational
    case audit
    case job
    case security
    case sharing
}

public enum NotificationStatus: String, Codable, Sendable {
    case pending
    case bounced
    case dropped
    case deferred
    case delivered
    case sent
    case outsideUsersSchedule
    case notificationsDisabled
    case noNotificationActions
    case sendingFailed
    case throttled
    case unableToGetSettings
}

public struct Notification: Codable, Identifiable, Sendable {
    public let id: String
    public let timestamp: String
    public let createTimestamp: String
    public let sentTimestamp: String?
    public let alertId: String?
    public let alertType: String?
    public let actorId: String
    public let actorName: String?
    public let actorType: String
    public let actorAccountId: String
    public let userId: String
    public let accountId: String
    public let read: Bool
    public let status: NotificationStatus
    public let category: NotificationCategory
    public let description: String?
    public let notificationActions: [String]
    public let dataSchemas: [String]
    public let data: [String: AnyCodable]
}

public struct ListNotificationsParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var timestampLte: String?
    public var timestampGte: String?
    public var alertId: String?
    public var alertType: String?
    public var actorId: String?
    public var actorType: String?
    public var actorAccountId: String?
    public var category: NotificationCategory?
    public var userId: String?
    public var read: Bool?
    public var status: NotificationStatus?
    public var includeV1Notifications: Bool?
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
        b.add("alertId", alertId)
        b.add("alertType", alertType)
        b.add("actorId", actorId)
        b.add("actorType", actorType)
        b.add("actorAccountId", actorAccountId)
        if let category { b.add("category", category.rawValue) }
        b.add("userId", userId)
        b.add("read", read)
        if let status { b.add("status", status.rawValue) }
        b.add("includeV1Notifications", includeV1Notifications)
        b.addSort(sort)
        b.add("language", language)
        return b.items
    }
}
