import Foundation

/// Observable authentication state for SwiftUI integration.
///
/// On iOS 17+, this class is compatible with the Observation framework.
/// On iOS 16, use it as an `ObservableObject` with `@Published` properties.
@MainActor
public final class AuthState: ObservableObject, Sendable {
    /// Current access token.
    @Published public private(set) var token: String?

    /// Base URL for API calls (e.g., "https://c001.eagleeyenetworks.com").
    @Published public private(set) var baseUrl: String?

    /// Session ID for proxy-based token refresh.
    @Published public private(set) var sessionId: String?

    /// Email of the authenticated user.
    @Published public private(set) var userEmail: String?

    /// When the current access token expires.
    @Published public private(set) var tokenExpiration: Date?

    /// Whether a token refresh is currently in progress.
    @Published public private(set) var isRefreshing: Bool = false

    /// Whether the user is currently authenticated with a non-expired token.
    public var isAuthenticated: Bool {
        guard let token, !token.isEmpty, let expiration = tokenExpiration else {
            return false
        }
        return expiration > Date()
    }

    public init() {}

    // MARK: - Public Token Injection

    /// Inject authentication credentials directly (e.g., from a QR code or external token source).
    /// This bypasses the OAuth flow and sets the token and base URL directly.
    public func inject(token: String, baseUrl: String, expiresIn: Int) {
        self.token = token
        self.baseUrl = baseUrl
        self.sessionId = nil
        self.userEmail = nil
        self.tokenExpiration = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    // MARK: - Internal Mutators

    func update(token: String, expiresIn: Int, baseUrl: String, sessionId: String, userEmail: String?) {
        self.token = token
        self.baseUrl = baseUrl
        self.sessionId = sessionId
        self.userEmail = userEmail
        self.tokenExpiration = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    func updateToken(_ token: String, expiresIn: Int) {
        self.token = token
        self.tokenExpiration = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    func setRefreshing(_ value: Bool) {
        self.isRefreshing = value
    }

    func clear() {
        token = nil
        baseUrl = nil
        sessionId = nil
        userEmail = nil
        tokenExpiration = nil
        isRefreshing = false
    }

    /// Restore state from persisted storage.
    func restore(token: String, baseUrl: String, sessionId: String, userEmail: String?, tokenExpiration: Date) {
        self.token = token
        self.baseUrl = baseUrl
        self.sessionId = sessionId
        self.userEmail = userEmail
        self.tokenExpiration = tokenExpiration
    }
}
