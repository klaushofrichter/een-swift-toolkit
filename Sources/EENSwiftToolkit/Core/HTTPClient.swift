import Foundation

/// Actor-based HTTP client for authenticated EEN API requests.
actor HTTPClient {
    private let session: URLSession
    private let authState: AuthState
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(authState: AuthState, configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
        self.authState = authState
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    /// Perform a request and decode the response as `T`.
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await performRequest(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw EENError(code: .apiError, message: "Failed to decode response: \(error.localizedDescription)")
        }
    }

    /// Perform a request that returns no body (e.g., DELETE).
    func requestVoid(_ endpoint: Endpoint) async throws {
        _ = try await performRequest(endpoint)
    }

    /// Perform a request and return raw `Data` (e.g., image downloads).
    func requestData(_ endpoint: Endpoint) async throws -> Data {
        try await performRequest(endpoint)
    }

    /// Perform a request and return raw `Data` along with response headers.
    /// Used for image endpoints where metadata is returned in HTTP headers.
    func requestDataWithHeaders(_ endpoint: Endpoint) async throws -> (Data, [AnyHashable: Any]) {
        let (data, httpResponse) = try await performRequestWithResponse(endpoint)
        return (data, httpResponse.allHeaderFields)
    }

    // MARK: - Internal

    private func performRequest(_ endpoint: Endpoint) async throws -> Data {
        let (data, _) = try await performRequestWithResponse(endpoint)
        return data
    }

    private func performRequestWithResponse(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        let (baseUrl, token) = await (authState.baseUrl, authState.token)

        guard let baseUrl, let token else {
            throw EENError(code: .authRequired, message: "Authentication required")
        }

        let url = try buildURL(base: baseUrl, endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        for (key, value) in endpoint.additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        EENDebug.log("\(endpoint.method.rawValue) \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw EENError(code: .networkError, message: "Network request failed: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EENError(code: .networkError, message: "Invalid response type")
        }

        EENDebug.log("Response: \(httpResponse.statusCode) (\(data.count) bytes)")

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw try parseErrorResponse(data: data, statusCode: httpResponse.statusCode)
        }

        return (data, httpResponse)
    }

    private func buildURL(base: String, endpoint: Endpoint) throws -> URL {
        guard var components = URLComponents(string: base + endpoint.path) else {
            throw EENError(code: .validationError, message: "Invalid URL: \(base)\(endpoint.path)")
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
            // URLComponents does not percent-encode '+' in query values, but many servers
            // (including EEN API) parse query strings using form-encoding where '+' means space.
            // Manually encode '+' as '%2B' to preserve timestamp offsets like +00:00.
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
        }
        guard let url = components.url else {
            throw EENError(code: .validationError, message: "Failed to construct URL from components")
        }
        return url
    }

    private func parseErrorResponse(data: Data, statusCode: Int) throws -> EENError {
        let code = errorCode(forHTTPStatus: statusCode)
        var message = HTTPURLResponse.localizedString(forStatusCode: statusCode)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let msg = json["message"] as? String {
                message = msg
            } else if let err = json["error"] as? String {
                message = err
            }
        }

        return EENError(code: code, message: message, status: statusCode)
    }
}

/// Type-erased wrapper for encoding arbitrary `Encodable` values.
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encode = { encoder in try value.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
