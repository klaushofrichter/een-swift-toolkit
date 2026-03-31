import Foundation

public struct User: Codable, Identifiable, Sendable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let accountId: String?
    public let timeZone: String?
    public let language: String?
    public let phone: String?
    public let mobilePhone: String?
    public let permissions: [String]?
    public let lastLogin: String?
    public let isActive: Bool?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct UserProfile: Codable, Identifiable, Sendable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let accountId: String?
    public let timeZone: String?
    public let language: String?
}

public struct ListUsersParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var include: [String]?

    public init(pageSize: Int? = nil, pageToken: String? = nil, include: [String]? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
        self.include = include
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.addInclude(include)
        return b.items
    }
}

public struct GetUserParams: Sendable {
    public var include: [String]?

    public init(include: [String]? = nil) {
        self.include = include
    }
}
