import Foundation

/// Configuration for the EEN OAuth proxy and API.
/// Update these values for your environment before running.
enum AppConfig {
    /// OAuth proxy URL. Defaults to Cloudflare Workers proxy for device builds.
    /// Override with PROXY_URL env var for local simulator testing.
    static let proxyUrl = ProcessInfo.processInfo.environment["PROXY_URL"]
        ?? "https://een-mobile-proxy.klaushofrichter.workers.dev"

    /// EEN API client ID. Must match the proxy's CLIENT_ID.
    static let clientId = ProcessInfo.processInfo.environment["EEN_CLIENT_ID"]
        ?? "PREVIEW-KLAUS-MOBILE"

    /// OAuth redirect URI. Must match a URI registered with EEN for this client.
    static let redirectUri = ProcessInfo.processInfo.environment["EEN_REDIRECT_URI"]
        ?? "https://een-mobile-proxy.klaushofrichter.workers.dev"
}
