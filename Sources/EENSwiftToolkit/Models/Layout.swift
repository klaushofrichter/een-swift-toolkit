import Foundation

public enum LayoutPaneType: String, Codable, Sendable {
    case preview
    case compositePreview
}

public enum CameraAspectRatio: String, Codable, Sendable {
    case sixteenByNine = "16x9"
    case fourByThree = "4x3"
}

public struct LayoutPane: Codable, Sendable {
    public let id: Int
    public let name: String
    public let type: LayoutPaneType
    public let size: Int
    public let cameraId: String
    public let compositeId: String?

    public init(id: Int, name: String, type: LayoutPaneType, size: Int, cameraId: String, compositeId: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.cameraId = cameraId
        self.compositeId = compositeId
    }
}

public struct LayoutSettings: Codable, Sendable {
    public let showCameraBorder: Bool
    public let showCameraName: Bool
    public let cameraAspectRatio: CameraAspectRatio
    public let paneColumns: Int

    public init(showCameraBorder: Bool, showCameraName: Bool, cameraAspectRatio: CameraAspectRatio, paneColumns: Int) {
        self.showCameraBorder = showCameraBorder
        self.showCameraName = showCameraName
        self.cameraAspectRatio = cameraAspectRatio
        self.paneColumns = paneColumns
    }
}

public struct CameraStatusCounts: Codable, Sendable {
    public let online: Int?
    public let offline: Int?
    public let error: Int?
    public let other: Int?
}

public struct LayoutPermissions: Codable, Sendable {
    public let read: Bool?
    public let edit: Bool?
    public let delete: Bool?
}

public struct Layout: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let accountId: String
    public let panes: [LayoutPane]
    public let settings: LayoutSettings
    public let effectivePermissions: LayoutPermissions?
    public let resourceCounts: ResourceCounts?
    public let resourceStatusCounts: ResourceStatusCounts?
    public let qRelevance: Double?

    public struct ResourceCounts: Codable, Sendable {
        public let cameras: Int?
    }

    public struct ResourceStatusCounts: Codable, Sendable {
        public let cameras: CameraStatusCounts?
    }
}

public struct ListLayoutsParams: Sendable, QueryParamEncodable {
    public var pageSize: Int?
    public var pageToken: String?
    public var include: [String]?
    public var sort: [String]?
    public var name: String?
    public var nameIn: [String]?
    public var nameContains: String?
    public var idIn: [String]?
    public var q: String?
    public var qRelevanceGte: Double?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }

    func toQueryItems() -> [URLQueryItem] {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: pageSize, pageToken: pageToken)
        b.addInclude(include)
        b.addSort(sort)
        b.add("name", name)
        b.addIn("name", nameIn)
        b.add("name__contains", nameContains)
        b.addIn("id", idIn)
        b.add("q", q)
        b.addGte("qRelevance", qRelevanceGte)
        return b.items
    }
}

public struct CreateLayoutParams: Codable, Sendable {
    public let name: String
    public let settings: LayoutSettings
    public let panes: [LayoutPane]?

    public init(name: String, settings: LayoutSettings, panes: [LayoutPane]? = nil) {
        self.name = name
        self.settings = settings
        self.panes = panes
    }
}

public struct UpdateLayoutParams: Codable, Sendable {
    public let name: String?
    public let settings: LayoutSettings?
    public let panes: [LayoutPane]?

    public init(name: String? = nil, settings: LayoutSettings? = nil, panes: [LayoutPane]? = nil) {
        self.name = name
        self.settings = settings
        self.panes = panes
    }
}
