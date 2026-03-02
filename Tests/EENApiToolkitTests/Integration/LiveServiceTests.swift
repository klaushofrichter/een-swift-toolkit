import Testing
import Foundation
@testable import EENApiToolkit

/// Integration tests that run against a live EEN mobile proxy and real EEN account.
///
/// These tests require a `test-credentials.json` file (produced by `scripts/get-test-token.js`)
/// or the equivalent environment variables: `EEN_ACCESS_TOKEN`, `EEN_SESSION_ID`,
/// `EEN_BASE_URL`, `EEN_USER_EMAIL`.
///
/// Run with: `swift test --filter Integration`
@Suite("Integration: Live Services")
struct LiveServiceTests {

    // MARK: - Credential Loading

    struct TestCredentials {
        let accessToken: String
        let sessionId: String
        let httpsBaseUrl: String
        let userEmail: String?
        let expiresIn: Int
    }

    private struct CredentialFile: Codable {
        let accessToken: String
        let sessionId: String
        let httpsBaseUrl: String
        let userEmail: String?
        let expiresIn: Int
    }

    /// Load credentials from test-credentials.json or environment variables.
    static func loadCredentials() throws -> TestCredentials {
        // Try JSON file first (relative to package root)
        let fileManager = FileManager.default
        let candidates = [
            // When run via `swift test` from EENApiToolkit/
            "test-credentials.json",
            // When run from a different CWD
            ProcessInfo.processInfo.environment["TEST_CREDENTIALS_PATH"]
        ].compactMap { $0 }

        for path in candidates {
            let url: URL
            if path.hasPrefix("/") {
                url = URL(fileURLWithPath: path)
            } else {
                url = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(path)
            }
            if let data = try? Data(contentsOf: url) {
                let cred = try JSONDecoder().decode(CredentialFile.self, from: data)
                return TestCredentials(
                    accessToken: cred.accessToken,
                    sessionId: cred.sessionId,
                    httpsBaseUrl: cred.httpsBaseUrl,
                    userEmail: cred.userEmail,
                    expiresIn: cred.expiresIn
                )
            }
        }

        // Fallback to environment variables
        let env = ProcessInfo.processInfo.environment
        guard let token = env["EEN_ACCESS_TOKEN"],
              let sessionId = env["EEN_SESSION_ID"],
              let baseUrl = env["EEN_BASE_URL"] else {
            struct MissingCredentials: Error, CustomStringConvertible {
                let description = "No test-credentials.json found and EEN_ACCESS_TOKEN/EEN_SESSION_ID/EEN_BASE_URL env vars not set. Run scripts/get-test-token.js first."
            }
            throw MissingCredentials()
        }

        return TestCredentials(
            accessToken: token,
            sessionId: sessionId,
            httpsBaseUrl: baseUrl,
            userEmail: env["EEN_USER_EMAIL"],
            expiresIn: Int(env["EEN_EXPIRES_IN"] ?? "3600") ?? 3600
        )
    }

    /// Create an authenticated toolkit instance.
    @MainActor
    static func makeToolkit(credentials: TestCredentials) -> EENToolkit {
        let proxyUrl = ProcessInfo.processInfo.environment["PROXY_URL"] ?? "http://127.0.0.1:3333"
        let config = EENToolkitConfig(
            proxyUrl: proxyUrl,
            clientId: "PREVIEW-KLAUS-MOBILE",
            redirectUri: proxyUrl,
            storageStrategy: .memory
        )
        let toolkit = EENToolkit(config: config)
        toolkit.authState.update(
            token: credentials.accessToken,
            expiresIn: credentials.expiresIn,
            baseUrl: credentials.httpsBaseUrl,
            sessionId: credentials.sessionId,
            userEmail: credentials.userEmail
        )
        return toolkit
    }

    // MARK: - Tests

    @Test("List cameras returns results with id and name")
    func listCameras() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let result = try await toolkit.cameras.list()
        #expect(!result.results.isEmpty, "Expected at least one camera")

        let camera = result.results[0]
        #expect(!camera.id.isEmpty)
        #expect(!camera.name.isEmpty)
    }

    @Test("Get single camera by id")
    func getSingleCamera() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        // First get the list to find a camera id
        let list = try await toolkit.cameras.list()
        #expect(!list.results.isEmpty, "Need at least one camera to test get")

        let cameraId = list.results[0].id
        let camera = try await toolkit.cameras.get(id: cameraId)
        #expect(camera.id == cameraId)
    }

    @Test("List bridges returns results")
    func listBridges() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let result = try await toolkit.bridges.list()
        // Bridges may be empty for some accounts, just verify the call succeeds
        #expect(result.results.count >= 0)
    }

    @Test("List events with required params")
    func listEvents() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        // Get a camera to use as actor
        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty, "Need at least one camera to query events")

        let cameraId = cameras.results[0].id
        let oneDayAgo = formatTimestamp(Date().addingTimeInterval(-86400))

        let params = ListEventsParams(
            actor: cameraId,
            typeIn: ["een.motionDetectionEvent.v1"],
            startTimestampGte: oneDayAgo,
            pageSize: 5
        )
        let result = try await toolkit.events.list(params: params)
        // Events may or may not exist, just verify the call succeeds
        #expect(result.results.count >= 0)
    }

    @Test("Get current user returns user with email")
    func getCurrentUser() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let user = try await toolkit.users.getCurrentUser()
        #expect(!user.id.isEmpty)
        // If we have a test email, verify it matches
        if let expectedEmail = creds.userEmail {
            #expect(user.email == expectedEmail)
        }
    }

    @Test("Token refresh succeeds and updates token")
    func tokenRefresh() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let originalToken = await toolkit.authState.token
        #expect(originalToken != nil)

        try await toolkit.auth.refreshToken()

        let newToken = await toolkit.authState.token
        #expect(newToken != nil)
        #expect(newToken != originalToken, "Token should change after refresh")
    }

    @Test("Revoke token clears auth and subsequent call fails")
    func revokeToken() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        // Verify we're authenticated first
        let user = try await toolkit.users.getCurrentUser()
        #expect(!user.id.isEmpty)

        // Revoke the session
        try await toolkit.auth.revokeToken()

        // Auth state should be cleared
        let token = await toolkit.authState.token
        #expect(token == nil, "Token should be nil after revoke")

        // Subsequent API call should fail with authRequired
        do {
            _ = try await toolkit.users.getCurrentUser()
            Issue.record("Expected authRequired error after revoke")
        } catch let error as EENError {
            #expect(error.code == .authRequired)
        }
    }
}
