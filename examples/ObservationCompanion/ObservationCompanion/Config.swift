import Foundation

enum AppConfig {
    static let proxyUrl = ProcessInfo.processInfo.environment["EEN_PROXY_URL"]
        ?? "http://127.0.0.1:3333"

    static let clientId = ProcessInfo.processInfo.environment["EEN_CLIENT_ID"]
        ?? "PREVIEW-KLAUS-MOBILE"

    /// OAuth redirect goes to the proxy, which returns the code via redirect
    static let redirectUri = "http://127.0.0.1:3333"

    /// URL scheme for QR codes and deep links
    static let urlScheme = "eenobserve"
}
