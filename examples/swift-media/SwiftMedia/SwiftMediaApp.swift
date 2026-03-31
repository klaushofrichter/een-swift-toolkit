import SwiftUI
import EENSwiftToolkit

@main
struct SwiftMediaApp: App {
    let toolkit: EENToolkit

    init() {
        let config = EENToolkitConfig(
            proxyUrl: AppConfig.proxyUrl,
            clientId: AppConfig.clientId,
            redirectUri: AppConfig.redirectUri,
            storageStrategy: .keychain
        )
        toolkit = EENToolkit(config: config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(toolkit: toolkit)
                .environmentObject(toolkit.authState)
                .task {
                    // Try environment variables first (for XCUITest),
                    // then file-based injection (for simctl testing),
                    // then fall back to keychain session restore.
                    if await injectFromEnvironment() {
                        return
                    }
                    if await injectTestCredentials() {
                        return
                    }
                    let _ = await toolkit.restoreSession()
                }
        }
    }

    /// Read credentials from environment variables (set by XCUITest launchEnvironment).
    private func injectFromEnvironment() async -> Bool {
        guard let token = ProcessInfo.processInfo.environment["TEST_TOKEN"],
              let baseUrl = ProcessInfo.processInfo.environment["TEST_BASE_URL"],
              let sessionId = ProcessInfo.processInfo.environment["TEST_SESSION_ID"],
              !token.isEmpty else {
            return false
        }

        let expiresIn = Int(ProcessInfo.processInfo.environment["TEST_EXPIRES_IN"] ?? "3600") ?? 3600
        let email = ProcessInfo.processInfo.environment["TEST_USER_EMAIL"]
        let service = "com.een.api-toolkit"
        let expiration = String(Date().addingTimeInterval(TimeInterval(expiresIn)).timeIntervalSince1970)

        saveToKeychain(service: service, key: "een_token", value: token)
        saveToKeychain(service: service, key: "een_base_url", value: baseUrl)
        saveToKeychain(service: service, key: "een_session_id", value: sessionId)
        saveToKeychain(service: service, key: "een_token_expiration", value: expiration)
        if let email, !email.isEmpty {
            saveToKeychain(service: service, key: "een_user_email", value: email)
        }

        let restored = await toolkit.restoreSession()
        if restored {
            print("[SwiftMedia] Authenticated via environment variables")
        }
        return restored
    }

    /// Look for a test-credentials.json in the app's Documents directory.
    private func injectTestCredentials() async -> Bool {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        let credentialsUrl = docs.appendingPathComponent("test-credentials.json")
        guard let data = try? Data(contentsOf: credentialsUrl),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["accessToken"] as? String,
              let baseUrl = json["httpsBaseUrl"] as? String,
              let sessionId = json["sessionId"] as? String,
              let expiresIn = json["expiresIn"] as? Int else {
            return false
        }

        let email = json["userEmail"] as? String
        let service = "com.een.api-toolkit"
        let expiration = String(Date().addingTimeInterval(TimeInterval(expiresIn)).timeIntervalSince1970)

        saveToKeychain(service: service, key: "een_token", value: token)
        saveToKeychain(service: service, key: "een_base_url", value: baseUrl)
        saveToKeychain(service: service, key: "een_session_id", value: sessionId)
        saveToKeychain(service: service, key: "een_token_expiration", value: expiration)
        if let email {
            saveToKeychain(service: service, key: "een_user_email", value: email)
        }

        try? FileManager.default.removeItem(at: credentialsUrl)

        let restored = await toolkit.restoreSession()
        if restored {
            print("[SwiftMedia] Authenticated via injected test credentials")
        }
        return restored
    }

    private func saveToKeychain(service: String, key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
