import Foundation

/// Response from the proxy's token exchange endpoint.
/// The `httpsBaseUrl` field can be a string (`"https://api.c021.eagleeyenetworks.com"`)
/// or an object (`{"hostname":"api.c021.eagleeyenetworks.com","port":443}`).
public struct TokenResponse: Sendable {
    public let accessToken: String
    public let expiresIn: Int
    public let httpsBaseUrl: String
    public let userEmail: String?
    public let sessionId: String
}

extension TokenResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case accessToken, expiresIn, httpsBaseUrl, userEmail, sessionId
    }

    private struct BaseUrlObject: Decodable {
        let hostname: String
        let port: Int?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        userEmail = try container.decodeIfPresent(String.self, forKey: .userEmail)
        sessionId = try container.decode(String.self, forKey: .sessionId)

        // httpsBaseUrl may be a string or an object { hostname, port }
        if let urlString = try? container.decode(String.self, forKey: .httpsBaseUrl) {
            httpsBaseUrl = urlString
        } else if let urlObject = try? container.decode(BaseUrlObject.self, forKey: .httpsBaseUrl) {
            let port = urlObject.port
            if let port, port != 443 {
                httpsBaseUrl = "https://\(urlObject.hostname):\(port)"
            } else {
                httpsBaseUrl = "https://\(urlObject.hostname)"
            }
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(codingPath: [CodingKeys.httpsBaseUrl],
                                      debugDescription: "httpsBaseUrl must be a string or {hostname, port} object")
            )
        }
    }
}

extension TokenResponse: Encodable {}

/// Response from the proxy's token refresh endpoint.
struct RefreshTokenResponse: Codable, Sendable {
    let accessToken: String
    let expiresIn: Int
}

/// Manages the OAuth authentication flow via the proxy server.
public actor AuthManager {
    private let config: EENToolkitConfig
    private let tokenStorage: TokenStorage
    private let authState: AuthState
    private var refreshTask: Task<Void, Error>?
    private var autoRefreshTask: Task<Void, Never>?

    // Storage keys
    private enum StorageKey {
        static let token = "een_token"
        static let baseUrl = "een_base_url"
        static let sessionId = "een_session_id"
        static let userEmail = "een_user_email"
        static let tokenExpiration = "een_token_expiration"
    }

    private var normalizedProxyUrl: String {
        config.proxyUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    public init(config: EENToolkitConfig, authState: AuthState, tokenStorage: TokenStorage? = nil) {
        self.config = config
        self.authState = authState
        self.tokenStorage = tokenStorage ?? {
            switch config.storageStrategy {
            case .keychain: return KeychainTokenStorage()
            case .memory: return InMemoryTokenStorage()
            }
        }()
    }

    /// Generate the OAuth authorization URL for the user to authenticate.
    public func getAuthUrl() -> URL {
        let state = UUID().uuidString
        var components = URLComponents(string: "https://auth.eagleeyenetworks.com/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "vms.all"),
            URLQueryItem(name: "state", value: state)
        ]
        return components.url!
    }

    /// Handle the OAuth callback after the user authenticates.
    /// Exchanges the authorization code for tokens via the proxy.
    @discardableResult
    public func handleCallback(code: String, state: String?) async throws -> TokenResponse {
        let proxyUrl = normalizedProxyUrl
        guard let url = URL(string: "\(proxyUrl)/proxy/getAccessToken") else {
            throw EENError(code: .validationError, message: "Invalid proxy URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "code=\(code.urlEncoded)&redirect_uri=\(config.redirectUri.urlEncoded)"
        request.httpBody = body.data(using: .utf8)

        EENDebug.log("Exchanging auth code via proxy")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EENError(code: .networkError, message: "Invalid response from proxy")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw EENError(code: .authFailed, message: "Token exchange failed: \(message)", status: httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Validate the hostname
        _ = try HostnameValidator.validateBaseUrl(tokenResponse.httpsBaseUrl)

        // Update auth state on main actor
        await MainActor.run {
            authState.update(
                token: tokenResponse.accessToken,
                expiresIn: tokenResponse.expiresIn,
                baseUrl: tokenResponse.httpsBaseUrl,
                sessionId: tokenResponse.sessionId,
                userEmail: tokenResponse.userEmail
            )
        }

        // Persist tokens
        try persistAuthState(tokenResponse)

        // Schedule auto-refresh
        scheduleAutoRefresh(expiresIn: tokenResponse.expiresIn)

        EENDebug.log("Authentication successful for \(tokenResponse.userEmail ?? "unknown")")

        return tokenResponse
    }

    /// Refresh the access token using the proxy server.
    public func refreshToken() async throws {
        // Avoid concurrent refresh calls
        if let existing = refreshTask {
            return try await existing.value
        }

        let proxyUrl = normalizedProxyUrl
        let task = Task { [weak self] in
            guard let self else { return }
            defer { Task { await self.clearRefreshTask() } }

            let sessionId = await self.authState.sessionId
            guard let sessionId else {
                throw EENError(code: .authRequired, message: "No session ID available for refresh")
            }

            await MainActor.run { self.authState.setRefreshing(true) }
            defer { Task { await MainActor.run { self.authState.setRefreshing(false) } } }
            guard let url = URL(string: "\(proxyUrl)/proxy/refreshAccessToken") else {
                throw EENError(code: .validationError, message: "Invalid proxy URL")
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")

            EENDebug.log("Refreshing access token")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw EENError(code: .networkError, message: "Invalid response from proxy")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    await self.clearAuth()
                    throw EENError(code: .tokenExpired, message: "Session expired", status: 401)
                }
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw EENError(code: .authFailed, message: "Token refresh failed: \(message)", status: httpResponse.statusCode)
            }

            let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)

            await MainActor.run {
                self.authState.updateToken(refreshResponse.accessToken, expiresIn: refreshResponse.expiresIn)
            }

            // Update persisted token
            try? self.tokenStorage.save(key: StorageKey.token, value: refreshResponse.accessToken)
            let expiration = Date().addingTimeInterval(TimeInterval(refreshResponse.expiresIn))
            try? self.tokenStorage.save(key: StorageKey.tokenExpiration, value: String(expiration.timeIntervalSince1970))

            await self.scheduleAutoRefresh(expiresIn: refreshResponse.expiresIn)

            EENDebug.log("Token refreshed, expires in \(refreshResponse.expiresIn)s")
        }

        refreshTask = task  // Assign before awaiting to prevent concurrent refresh tasks
        try await task.value
    }

    /// Revoke the current session and clear all auth state.
    public func revokeToken() async throws {
        let sessionId = await authState.sessionId

        guard let sessionId else {
            await clearAuth()
            return
        }

        let proxyUrl = normalizedProxyUrl
        guard let url = URL(string: "\(proxyUrl)/proxy/revoke") else {
            await clearAuth()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")

        EENDebug.log("Revoking token")

        // Best-effort revoke -- don't throw on failure
        let _ = try? await URLSession.shared.data(for: request)

        // Always clear local state regardless of revoke outcome
        await clearAuth()
    }

    /// Attempt to restore a previous session from persisted storage.
    public func restoreSession() async -> Bool {
        guard let token = try? tokenStorage.load(key: StorageKey.token),
              let baseUrl = try? tokenStorage.load(key: StorageKey.baseUrl),
              let sessionId = try? tokenStorage.load(key: StorageKey.sessionId),
              let expirationStr = try? tokenStorage.load(key: StorageKey.tokenExpiration),
              let expirationInterval = Double(expirationStr)
        else {
            return false
        }

        let expiration = Date(timeIntervalSince1970: expirationInterval)
        let userEmail = try? tokenStorage.load(key: StorageKey.userEmail)

        // Validate the stored base URL
        guard (try? HostnameValidator.validateBaseUrl(baseUrl)) != nil else {
            await clearAuth()
            return false
        }

        await MainActor.run {
            authState.restore(
                token: token,
                baseUrl: baseUrl,
                sessionId: sessionId,
                userEmail: userEmail,
                tokenExpiration: expiration
            )
        }

        // If token is expired or about to expire, refresh immediately
        if expiration.timeIntervalSinceNow < 60 {
            do {
                try await refreshToken()
            } catch {
                await clearAuth()
                return false
            }
        } else {
            let remainingSeconds = Int(expiration.timeIntervalSinceNow)
            scheduleAutoRefresh(expiresIn: remainingSeconds)
        }

        EENDebug.log("Session restored for \(userEmail ?? "unknown")")
        return true
    }

    // MARK: - Private

    private func clearRefreshTask() {
        refreshTask = nil
    }

    private func scheduleAutoRefresh(expiresIn: Int) {
        autoRefreshTask?.cancel()

        // Schedule refresh: 5 minutes before expiry or at 50% of TTL, whichever is earlier
        let fiveMinBefore = max(expiresIn - 300, 5)
        let halfTTL = max(expiresIn / 2, 5)
        let delaySeconds = min(fiveMinBefore, halfTTL)

        EENDebug.log("Scheduling auto-refresh in \(delaySeconds)s")

        autoRefreshTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delaySeconds))
            guard !Task.isCancelled else { return }
            try? await self?.refreshToken()
        }
    }

    private func persistAuthState(_ response: TokenResponse) throws {
        try tokenStorage.save(key: StorageKey.token, value: response.accessToken)
        try tokenStorage.save(key: StorageKey.baseUrl, value: response.httpsBaseUrl)
        try tokenStorage.save(key: StorageKey.sessionId, value: response.sessionId)
        if let email = response.userEmail {
            try tokenStorage.save(key: StorageKey.userEmail, value: email)
        }
        let expiration = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        try tokenStorage.save(key: StorageKey.tokenExpiration, value: String(expiration.timeIntervalSince1970))
    }

    private func clearAuth() async {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil

        await MainActor.run { authState.clear() }

        try? tokenStorage.delete(key: StorageKey.token)
        try? tokenStorage.delete(key: StorageKey.baseUrl)
        try? tokenStorage.delete(key: StorageKey.sessionId)
        try? tokenStorage.delete(key: StorageKey.userEmail)
        try? tokenStorage.delete(key: StorageKey.tokenExpiration)
    }
}

// MARK: - String URL Encoding Helper

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
