import Foundation

/// Storage strategy for authentication tokens.
public enum StorageStrategy: String, Sendable {
    case keychain
    case memory
}

/// Configuration for the EEN API Toolkit.
public struct EENToolkitConfig: Sendable {
    /// URL of the OAuth proxy server (e.g., "https://my-proxy.workers.dev").
    public let proxyUrl: String

    /// OAuth client ID registered with Eagle Eye Networks.
    public let clientId: String

    /// OAuth redirect URI (e.g., "myapp://callback").
    public let redirectUri: String

    /// Token storage strategy. Defaults to `.keychain`.
    public let storageStrategy: StorageStrategy

    /// Enable debug logging. Defaults to `false`.
    public let debug: Bool

    public init(
        proxyUrl: String,
        clientId: String,
        redirectUri: String,
        storageStrategy: StorageStrategy = .keychain,
        debug: Bool = false
    ) {
        self.proxyUrl = proxyUrl
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.storageStrategy = storageStrategy
        self.debug = debug
    }
}
