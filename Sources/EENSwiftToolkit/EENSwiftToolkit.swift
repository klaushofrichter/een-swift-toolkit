import Foundation

/// Central entry point for the EEN API Toolkit.
///
/// Usage:
/// ```swift
/// let toolkit = EENToolkit(config: .init(
///     proxyUrl: "https://my-proxy.workers.dev",
///     clientId: "my-client-id",
///     redirectUri: "myapp://callback"
/// ))
///
/// // Authenticate
/// let authUrl = await toolkit.auth.getAuthUrl()
/// // ... present in ASWebAuthenticationSession ...
/// try await toolkit.auth.handleCallback(code: code, state: state)
///
/// // Use services
/// let cameras = try await toolkit.cameras.list(params: .init(pageSize: 20))
/// let user = try await toolkit.users.getCurrentUser()
///
/// // Timestamps must use +00:00 format (not Z)
/// let ts = formatTimestamp(Date()) // "2024-01-15T10:30:00.000+00:00"
/// ```
public final class EENToolkit: Sendable {
    /// Configuration for this toolkit instance.
    public let config: EENToolkitConfig

    /// Observable authentication state (use in SwiftUI views).
    public let authState: AuthState

    /// Authentication manager for login, refresh, and logout.
    public let auth: AuthManager

    /// OAuth web session helper for browser-based authentication.
    @MainActor
    public let webSession: OAuthWebSession

    // MARK: - API Services

    public let users: UserService
    public let cameras: CameraService
    public let bridges: BridgeService
    public let layouts: LayoutService
    public let events: EventService
    public let eventMetrics: EventMetricService
    public let alerts: AlertService
    public let notifications: NotificationService
    public let eventSubscriptions: EventSubscriptionService
    public let automations: AutomationService
    public let media: MediaService
    public let feeds: FeedService
    public let jobs: JobService
    public let files: FileService
    public let downloads: DownloadService
    public let ptz: PTZService

    /// Create a new EEN API Toolkit instance.
    ///
    /// - Parameters:
    ///   - config: Configuration with proxy URL, client ID, and redirect URI.
    ///   - tokenStorage: Custom token storage implementation. Defaults to Keychain or InMemory based on config.
    @MainActor
    public init(config: EENToolkitConfig, tokenStorage: TokenStorage? = nil) {
        self.config = config

        // Enable debug logging if configured
        EENDebug.isEnabled = config.debug

        // Create shared auth state
        let authState = AuthState()
        self.authState = authState

        // Create auth manager
        self.auth = AuthManager(config: config, authState: authState, tokenStorage: tokenStorage)

        // Create web session helper
        self.webSession = OAuthWebSession()

        // Create HTTP client
        let client = HTTPClient(authState: authState)

        // Initialize all services
        self.users = UserService(client: client)
        self.cameras = CameraService(client: client)
        self.bridges = BridgeService(client: client)
        self.layouts = LayoutService(client: client)
        self.events = EventService(client: client)
        self.eventMetrics = EventMetricService(client: client)
        self.alerts = AlertService(client: client)
        self.notifications = NotificationService(client: client)
        self.eventSubscriptions = EventSubscriptionService(client: client, authState: authState)
        self.automations = AutomationService(client: client)
        self.media = MediaService(client: client)
        self.feeds = FeedService(client: client)
        self.jobs = JobService(client: client)
        self.files = FileService(client: client)
        self.downloads = DownloadService(client: client)
        self.ptz = PTZService(client: client)
    }

    /// Attempt to restore a previous authentication session from storage.
    /// Returns `true` if a valid session was restored.
    public func restoreSession() async -> Bool {
        await auth.restoreSession()
    }
}
