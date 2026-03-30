import Foundation

enum AppConfig {
    static let proxyUrl = ProcessInfo.processInfo.environment["PROXY_URL"]
        ?? "https://een-mobile-proxy.klaushofrichter.workers.dev"

    static let clientId = ProcessInfo.processInfo.environment["EEN_CLIENT_ID"]
        ?? "PREVIEW-KLAUS-MOBILE"

    static let redirectUri = ProcessInfo.processInfo.environment["EEN_REDIRECT_URI"]
        ?? "https://een-mobile-proxy.klaushofrichter.workers.dev"
}
