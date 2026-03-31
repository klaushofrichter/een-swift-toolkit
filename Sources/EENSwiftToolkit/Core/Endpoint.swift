import Foundation

/// HTTP methods used by the EEN API.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Describes an API endpoint request.
struct Endpoint {
    let method: HTTPMethod
    let path: String
    var queryItems: [URLQueryItem]
    var body: (any Encodable)?
    var additionalHeaders: [String: String]

    init(
        method: HTTPMethod = .get,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil,
        additionalHeaders: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
        self.additionalHeaders = additionalHeaders
    }
}
