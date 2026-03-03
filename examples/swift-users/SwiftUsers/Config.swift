import Foundation

/// Configuration for the EEN OAuth proxy and API.
/// Update these values for your environment before running.
enum AppConfig {
    /// OAuth proxy URL. Default works with the local mobile proxy.
    static let proxyUrl = ProcessInfo.processInfo.environment["PROXY_URL"]
        ?? "http://127.0.0.1:3333"

    /// EEN API client ID. Must match the proxy's CLIENT_ID.
    static let clientId = ProcessInfo.processInfo.environment["EEN_CLIENT_ID"]
        ?? "PREVIEW-KLAUS-MOBILE"

    /// OAuth redirect URI. Must match a URI registered with EEN for this client.
    /// For local development this is the proxy URL itself.
    static let redirectUri = ProcessInfo.processInfo.environment["EEN_REDIRECT_URI"]
        ?? "http://127.0.0.1:3333"
}
