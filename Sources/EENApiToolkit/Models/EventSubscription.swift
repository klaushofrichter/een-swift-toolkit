import Foundation

public enum EventSubscriptionLifecycle: String, Codable, Sendable {
    case temporary
    case persistent
}

public enum EventSubscriptionDeliveryType: String, Codable, Sendable {
    case serverSentEvents = "serverSentEvents.v1"
    case webhook = "webhook.v1"
}

public struct EventSubscriptionConfig: Codable, Sendable {
    public let lifeCycle: EventSubscriptionLifecycle
    public let timeToLiveSeconds: Int?
}

/// Delivery configuration -- either SSE or Webhook.
public enum DeliveryConfig: Codable, Sendable {
    case sse(sseUrl: String?)
    case webhook(secret: String?)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "serverSentEvents.v1":
            let sseUrl = try container.decodeIfPresent(String.self, forKey: .sseUrl)
            self = .sse(sseUrl: sseUrl)
        case "webhook.v1":
            let secret = try container.decodeIfPresent(String.self, forKey: .secret)
            self = .webhook(secret: secret)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown delivery type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sse(let sseUrl):
            try container.encode("serverSentEvents.v1", forKey: .type)
            try container.encodeIfPresent(sseUrl, forKey: .sseUrl)
        case .webhook(let secret):
            try container.encode("webhook.v1", forKey: .type)
            try container.encodeIfPresent(secret, forKey: .secret)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, sseUrl, secret
    }
}

public struct EventTypeFilter: Codable, Sendable {
    public let id: String
    public init(id: String) { self.id = id }
}

public struct EventSubscriptionFilter: Codable, Sendable {
    public let id: String
    public let actors: [String]
    public let types: [EventTypeFilter]
}

public struct EventSubscription: Codable, Identifiable, Sendable {
    public let id: String
    public let subscriptionConfig: EventSubscriptionConfig?
    public let deliveryConfig: DeliveryConfig
}

/// Delivery config for creating a new SSE subscription.
public struct SSEDeliveryConfigCreate: Codable, Sendable {
    public let type: String

    public init() { self.type = "serverSentEvents.v1" }
}

/// Delivery config for creating a new webhook subscription.
public struct WebhookDeliveryConfigCreate: Codable, Sendable {
    public let type: String
    public let webhookUrl: String
    public let technicalContactEmail: String
    public let technicalContactName: String

    public init(webhookUrl: String, technicalContactEmail: String, technicalContactName: String) {
        self.type = "webhook.v1"
        self.webhookUrl = webhookUrl
        self.technicalContactEmail = technicalContactEmail
        self.technicalContactName = technicalContactName
    }
}

public struct FilterCreate: Codable, Sendable {
    public let actors: [String]
    public let types: [EventTypeFilter]

    public init(actors: [String], types: [EventTypeFilter]) {
        self.actors = actors
        self.types = types
    }
}

/// Parameters for creating an event subscription.
public struct CreateEventSubscriptionParams: Codable, Sendable {
    public let deliveryConfig: DeliveryConfigCreateWrapper
    public let filters: [FilterCreate]

    public init(sseFilters: [FilterCreate]) {
        self.deliveryConfig = .sse
        self.filters = sseFilters
    }

    public init(webhookUrl: String, technicalContactEmail: String, technicalContactName: String, filters: [FilterCreate]) {
        self.deliveryConfig = .webhook(url: webhookUrl, email: technicalContactEmail, name: technicalContactName)
        self.filters = filters
    }
}

public enum DeliveryConfigCreateWrapper: Codable, Sendable {
    case sse
    case webhook(url: String, email: String, name: String)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sse:
            try container.encode("serverSentEvents.v1", forKey: .type)
        case .webhook(let url, let email, let name):
            try container.encode("webhook.v1", forKey: .type)
            try container.encode(url, forKey: .webhookUrl)
            try container.encode(email, forKey: .technicalContactEmail)
            try container.encode(name, forKey: .technicalContactName)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        if type == "webhook.v1" {
            self = .webhook(
                url: try container.decode(String.self, forKey: .webhookUrl),
                email: try container.decode(String.self, forKey: .technicalContactEmail),
                name: try container.decode(String.self, forKey: .technicalContactName)
            )
        } else {
            self = .sse
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, webhookUrl, technicalContactEmail, technicalContactName
    }
}

public struct ListEventSubscriptionsParams: Sendable, QueryParamEncodable {
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

/// SSE event received from a subscription stream.
public struct SSEEvent: Codable, Sendable {
    public let id: String
    public let startTimestamp: String
    public let endTimestamp: String?
    public let span: Bool?
    public let accountId: String?
    public let actorId: String
    public let actorAccountId: String?
    public let actorType: String?
    public let creatorId: String?
    public let type: String
    public let dataSchemas: [String]?
    public let data: [EventData]?
}

public enum SSEConnectionStatus: String, Sendable {
    case connecting
    case connected
    case disconnected
    case error
}
