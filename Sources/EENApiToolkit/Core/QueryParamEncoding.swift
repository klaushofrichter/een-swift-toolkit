import Foundation

/// Protocol for types that can encode themselves as URL query items.
protocol QueryParamEncodable {
    func toQueryItems() -> [URLQueryItem]
}

/// Common pagination parameters shared across list endpoints.
public struct PaginationParams: Sendable {
    public var pageSize: Int?
    public var pageToken: String?

    public init(pageSize: Int? = nil, pageToken: String? = nil) {
        self.pageSize = pageSize
        self.pageToken = pageToken
    }
}

/// Helper to build query items from optional values.
struct QueryItemBuilder {
    private(set) var items: [URLQueryItem] = []

    /// Append a string value if non-nil.
    mutating func add(_ name: String, _ value: String?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: value))
    }

    /// Append an integer value if non-nil.
    mutating func add(_ name: String, _ value: Int?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(value)))
    }

    /// Append a double value if non-nil.
    mutating func add(_ name: String, _ value: Double?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(value)))
    }

    /// Append a boolean value if non-nil.
    mutating func add(_ name: String, _ value: Bool?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(value)))
    }

    /// Append a comma-separated array using the `__in` filter convention.
    mutating func addIn(_ name: String, _ values: [String]?) {
        guard let values, !values.isEmpty else { return }
        items.append(URLQueryItem(name: "\(name)__in", value: values.joined(separator: ",")))
    }

    /// Append a comma-separated array using the `__contains` filter convention.
    mutating func addContains(_ name: String, _ values: [String]?) {
        guard let values, !values.isEmpty else { return }
        items.append(URLQueryItem(name: "\(name)__contains", value: values.joined(separator: ",")))
    }

    /// Append a comma-separated array using the `__any` filter convention.
    mutating func addAny(_ name: String, _ values: [String]?) {
        guard let values, !values.isEmpty else { return }
        items.append(URLQueryItem(name: "\(name)__any", value: values.joined(separator: ",")))
    }

    /// Append a `__ne` (not equal) filter.
    mutating func addNe(_ name: String, _ value: String?) {
        guard let value else { return }
        items.append(URLQueryItem(name: "\(name)__ne", value: value))
    }

    /// Append a `__gte` (greater than or equal) filter.
    mutating func addGte(_ name: String, _ value: String?) {
        guard let value else { return }
        items.append(URLQueryItem(name: "\(name)__gte", value: value))
    }

    /// Append a `__lte` (less than or equal) filter.
    mutating func addLte(_ name: String, _ value: String?) {
        guard let value else { return }
        items.append(URLQueryItem(name: "\(name)__lte", value: value))
    }

    /// Append a `__gte` filter with a numeric value.
    mutating func addGte(_ name: String, _ value: Int?) {
        guard let value else { return }
        items.append(URLQueryItem(name: "\(name)__gte", value: String(value)))
    }

    /// Append a `__lte` filter with a numeric value.
    mutating func addLte(_ name: String, _ value: Int?) {
        guard let value else { return }
        items.append(URLQueryItem(name: "\(name)__lte", value: String(value)))
    }

    /// Append a `__gte` filter with a double value.
    mutating func addGte(_ name: String, _ value: Double?) {
        guard let value else { return }
        items.append(URLQueryItem(name: "\(name)__gte", value: String(value)))
    }

    /// Append a comma-separated include list.
    mutating func addInclude(_ values: [String]?) {
        guard let values, !values.isEmpty else { return }
        items.append(URLQueryItem(name: "include", value: values.joined(separator: ",")))
    }

    /// Append a comma-separated sort list.
    mutating func addSort(_ values: [String]?) {
        guard let values, !values.isEmpty else { return }
        items.append(URLQueryItem(name: "sort", value: values.joined(separator: ",")))
    }

    /// Append pagination parameters.
    mutating func addPagination(pageSize: Int?, pageToken: String?) {
        add("pageSize", pageSize)
        add("pageToken", pageToken)
    }
}
