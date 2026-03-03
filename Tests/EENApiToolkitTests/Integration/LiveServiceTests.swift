import Testing
import Foundation
@testable import EENApiToolkit

/// Integration tests that run against a live EEN mobile proxy and real EEN account.
///
/// These tests require a `test-credentials.json` file (produced by `scripts/get-test-token.js`)
/// or the equivalent environment variables: `EEN_ACCESS_TOKEN`, `EEN_SESSION_ID`,
/// `EEN_BASE_URL`, `EEN_USER_EMAIL`.
///
/// Run with: `swift test --filter LiveServiceTests`
@Suite("Integration: Live Services", .serialized)
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
        let fileManager = FileManager.default
        let candidates = [
            "test-credentials.json",
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

    // MARK: - Camera Tests

    @Test("List cameras returns results with id and name")
    func listCameras() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let result = try await toolkit.cameras.list()
        #expect(!result.results.isEmpty, "Expected at least one camera")

        let camera = result.results[0]
        #expect(!camera.id.isEmpty)
        #expect(!camera.name.isEmpty)
        #expect(!camera.accountId.isEmpty)
    }

    @Test("List cameras with include returns deviceInfo and status")
    func listCamerasWithInclude() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        var params = ListCamerasParams(pageSize: 5)
        params.include = ["deviceInfo", "status"]
        let result = try await toolkit.cameras.list(params: params)
        #expect(!result.results.isEmpty, "Expected at least one camera")

        let camera = result.results[0]
        #expect(camera.status != nil, "Expected status with include")
        let status = camera.status?.effectiveStatus
        #expect(status != nil, "Expected effective status to be non-nil")

        #expect(camera.deviceInfo != nil, "Expected deviceInfo with include")
    }

    @Test("List cameras with pagination")
    func listCamerasWithPagination() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let params = ListCamerasParams(pageSize: 1)
        let page1 = try await toolkit.cameras.list(params: params)
        #expect(!page1.results.isEmpty)
        #expect(page1.results.count == 1, "Expected exactly 1 camera with pageSize=1")

        // If there are more cameras, fetch page 2
        if let nextToken = page1.nextPageToken {
            var page2Params = ListCamerasParams(pageSize: 1)
            page2Params.pageToken = nextToken
            let page2 = try await toolkit.cameras.list(params: page2Params)
            #expect(!page2.results.isEmpty, "Expected results on page 2")
            #expect(page2.results[0].id != page1.results[0].id, "Page 2 should have a different camera")
        }
    }

    @Test("Get single camera by id")
    func getSingleCamera() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let list = try await toolkit.cameras.list()
        #expect(!list.results.isEmpty, "Need at least one camera to test get")

        let cameraId = list.results[0].id
        let camera = try await toolkit.cameras.get(id: cameraId)
        #expect(camera.id == cameraId)
        #expect(!camera.name.isEmpty)
    }

    @Test("Get single camera with full include")
    func getSingleCameraWithInclude() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let list = try await toolkit.cameras.list()
        #expect(!list.results.isEmpty)

        let cameraId = list.results[0].id
        let camera = try await toolkit.cameras.get(
            id: cameraId,
            include: ["deviceInfo", "status", "shareDetails", "devicePosition", "tags", "capabilities"]
        )
        #expect(camera.id == cameraId)
        #expect(camera.status != nil, "Expected status with include")
        #expect(camera.deviceInfo != nil, "Expected deviceInfo with include")
        // shareDetails, devicePosition, tags, capabilities may or may not be populated
        // but the call should succeed without decoding errors
    }

    @Test("Get all cameras individually")
    func getAllCamerasIndividually() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let list = try await toolkit.cameras.list()
        #expect(!list.results.isEmpty)

        for listedCamera in list.results {
            let camera = try await toolkit.cameras.get(
                id: listedCamera.id,
                include: ["deviceInfo", "status"]
            )
            #expect(camera.id == listedCamera.id)
            #expect(camera.name == listedCamera.name)
            #expect(camera.status != nil, "Camera \(camera.name) should have status")
            #expect(camera.deviceInfo != nil, "Camera \(camera.name) should have deviceInfo")
        }
    }

    // MARK: - Bridge Tests

    @Test("List bridges returns at least one bridge")
    func listBridges() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let result = try await toolkit.bridges.list()
        #expect(!result.results.isEmpty, "Expected at least one bridge")

        let bridge = result.results[0]
        #expect(!bridge.id.isEmpty)
        #expect(!bridge.name.isEmpty)
    }

    @Test("List bridges with include returns deviceInfo, status, and networkInfo")
    func listBridgesWithInclude() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        var params = ListBridgesParams()
        params.include = ["deviceInfo", "status", "networkInfo"]
        let result = try await toolkit.bridges.list(params: params)
        #expect(!result.results.isEmpty)

        let bridge = result.results[0]
        #expect(bridge.status != nil, "Expected status with include")
        let status = bridge.status?.effectiveStatus
        #expect(status != nil, "Expected effective status to be non-nil")

        #expect(bridge.deviceInfo != nil, "Expected deviceInfo with include")
        #expect(bridge.networkInfo != nil, "Expected networkInfo with include")
    }

    @Test("Get single bridge by id with include")
    func getSingleBridgeWithInclude() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let list = try await toolkit.bridges.list()
        #expect(!list.results.isEmpty, "Need at least one bridge")

        let bridgeId = list.results[0].id
        let bridge = try await toolkit.bridges.get(
            id: bridgeId,
            include: ["deviceInfo", "status", "networkInfo"]
        )
        #expect(bridge.id == bridgeId)
        #expect(!bridge.name.isEmpty)
        #expect(bridge.status != nil, "Expected status with include")
        #expect(bridge.deviceInfo != nil, "Expected deviceInfo with include")
        #expect(bridge.networkInfo != nil, "Expected networkInfo with include")
    }

    // MARK: - Feed Tests

    @Test("List feeds for a camera returns results")
    func listFeedsForCamera() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        var params = ListFeedsParams()
        params.deviceId = cameraId
        let result = try await toolkit.feeds.list(params: params)
        #expect(!result.results.isEmpty, "Expected at least one feed for camera \(cameraId)")

        let feed = result.results[0]
        #expect(!feed.id.isEmpty)
        #expect(feed.deviceId == cameraId)
    }

    @Test("List feeds with include returns stream URLs")
    func listFeedsWithInclude() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        var params = ListFeedsParams()
        params.deviceId = cameras.results[0].id
        params.include = ["hlsUrl", "multipartUrl", "flvUrl", "rtspUrl"]
        let result = try await toolkit.feeds.list(params: params)
        #expect(!result.results.isEmpty)

        // At least one feed should have a stream URL populated
        let hasAnyUrl = result.results.contains { feed in
            feed.hlsUrl != nil || feed.multipartUrl != nil || feed.flvUrl != nil || feed.rtspUrl != nil
        }
        #expect(hasAnyUrl, "Expected at least one feed to have a stream URL with include")
    }

    @Test("List feeds for all cameras")
    func listFeedsForAllCameras() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        for camera in cameras.results {
            var params = ListFeedsParams()
            params.deviceId = camera.id
            let feeds = try await toolkit.feeds.list(params: params)
            // Every camera should have at least a preview feed
            #expect(!feeds.results.isEmpty, "Camera \(camera.name) (\(camera.id)) should have feeds")
        }
    }

    // MARK: - Event Tests

    @Test("List event types returns known types")
    func listEventTypes() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let result = try await toolkit.events.listTypes(params: ListEventTypesParams(pageSize: 100))
        #expect(!result.results.isEmpty, "Expected at least one event type")

        // Verify well-known event types exist
        let typeIds = result.results.map(\.type)
        #expect(typeIds.contains("een.motionDetectionEvent.v1"), "Expected motion detection event type")
    }

    @Test("List event field values for a camera")
    func listEventFieldValues() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let fieldValues = try await toolkit.events.listFieldValues(actor: "camera:\(cameraId)")
        #expect(!fieldValues.type.isEmpty, "Expected at least one event type for camera")
    }

    @Test("List events with motion detection type")
    func listEventsMotionDetection() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let oneDayAgo = formatTimestamp(Date().addingTimeInterval(-86400))
        let now = formatTimestamp(Date())

        var params = ListEventsParams(
            actor: "camera:\(cameraId)",
            typeIn: ["een.motionDetectionEvent.v1"],
            startTimestampGte: oneDayAgo,
            pageSize: 5
        )
        params.endTimestampLte = now
        let result = try await toolkit.events.list(params: params)
        #expect(result.results.count >= 0)

        if !result.results.isEmpty {
            let event = result.results[0]
            #expect(!event.id.isEmpty)
            #expect(event.type == "een.motionDetectionEvent.v1")
            #expect(event.actorId == cameraId)
            #expect(!event.startTimestamp.isEmpty)
        }
    }

    @Test("List events with dynamic event types from field values")
    func listEventsWithDynamicTypes() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let fieldValues = try await toolkit.events.listFieldValues(actor: "camera:\(cameraId)")
        #expect(!fieldValues.type.isEmpty, "Need at least one event type")

        // Query events using the first available event type from field values
        let eventType = fieldValues.type[0]
        let oneWeekAgo = formatTimestamp(Date().addingTimeInterval(-7 * 86400))
        let now = formatTimestamp(Date())

        var params = ListEventsParams(
            actor: "camera:\(cameraId)",
            typeIn: [eventType],
            startTimestampGte: oneWeekAgo,
            pageSize: 10
        )
        params.endTimestampLte = now
        let result = try await toolkit.events.list(params: params)
        #expect(result.results.count >= 0)

        if !result.results.isEmpty {
            #expect(result.results[0].type == eventType)
        }
    }

    @Test("List events with include for image URLs")
    func listEventsWithIncludeImageUrl() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let oneWeekAgo = formatTimestamp(Date().addingTimeInterval(-7 * 86400))
        let now = formatTimestamp(Date())

        var params = ListEventsParams(
            actor: "camera:\(cameraId)",
            typeIn: ["een.motionDetectionEvent.v1"],
            startTimestampGte: oneWeekAgo,
            pageSize: 5
        )
        params.endTimestampLte = now
        params.include = ["data.een.fullFrameImageUrl.v1"]
        let result = try await toolkit.events.list(params: params)
        #expect(result.results.count >= 0)

        // If events exist, check they have data with the included schema
        if let event = result.results.first {
            #expect(!event.data.isEmpty, "Expected event data with include")
        }
    }

    @Test("List events with multiple event types from field values")
    func listEventsMultipleTypes() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let fieldValues = try await toolkit.events.listFieldValues(actor: "camera:\(cameraId)")

        // Use up to 2 event types from field values
        let eventTypes = Array(fieldValues.type.prefix(2))
        #expect(!eventTypes.isEmpty, "Need at least one event type")

        let oneWeekAgo = formatTimestamp(Date().addingTimeInterval(-7 * 86400))
        let now = formatTimestamp(Date())

        var params = ListEventsParams(
            actor: "camera:\(cameraId)",
            typeIn: eventTypes,
            startTimestampGte: oneWeekAgo,
            pageSize: 10
        )
        params.endTimestampLte = now
        let result = try await toolkit.events.list(params: params)
        #expect(result.results.count >= 0)

        for event in result.results {
            #expect(eventTypes.contains(event.type), "Event type \(event.type) not in requested types \(eventTypes)")
        }
    }

    @Test("Get single event by id")
    func getSingleEvent() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let oneWeekAgo = formatTimestamp(Date().addingTimeInterval(-7 * 86400))
        let now = formatTimestamp(Date())

        var params = ListEventsParams(
            actor: "camera:\(cameraId)",
            typeIn: ["een.motionDetectionEvent.v1"],
            startTimestampGte: oneWeekAgo,
            pageSize: 1
        )
        params.endTimestampLte = now
        let result = try await toolkit.events.list(params: params)

        if let event = result.results.first {
            let fetched = try await toolkit.events.get(id: event.id)
            #expect(fetched.id == event.id)
            #expect(fetched.type == event.type)
            #expect(fetched.actorId == event.actorId)
        }
    }

    @Test("Get single event with include data schemas")
    func getSingleEventWithInclude() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let oneWeekAgo = formatTimestamp(Date().addingTimeInterval(-7 * 86400))
        let now = formatTimestamp(Date())

        var params = ListEventsParams(
            actor: "camera:\(cameraId)",
            typeIn: ["een.motionDetectionEvent.v1"],
            startTimestampGte: oneWeekAgo,
            pageSize: 1
        )
        params.endTimestampLte = now
        params.include = ["data.een.fullFrameImageUrl.v1"]
        let result = try await toolkit.events.list(params: params)

        if let event = result.results.first {
            let fetched = try await toolkit.events.get(
                id: event.id,
                include: ["data.een.fullFrameImageUrl.v1"]
            )
            #expect(fetched.id == event.id)
            #expect(!fetched.data.isEmpty, "Expected event data with include")
        }
    }

    // MARK: - Media / Image Tests

    @Test("Get live image from first camera")
    func getLiveImage() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let result = try await toolkit.media.getLiveImage(params: GetLiveImageParams(deviceId: cameraId))
        #expect(!result.imageData.isEmpty, "Expected non-empty image data")
        #expect(result.contentType == "image/jpeg")
        #expect(result.imageData.count > 100, "Image data too small, likely not a valid image")
    }

    @Test("Get live image from all cameras")
    func getLiveImageAllCameras() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        for camera in cameras.results {
            let result = try await toolkit.media.getLiveImage(
                params: GetLiveImageParams(deviceId: camera.id)
            )
            #expect(!result.imageData.isEmpty, "Camera \(camera.name) returned empty live image")
            #expect(result.imageData.count > 100, "Camera \(camera.name) live image too small")
        }
    }

    @Test("Get recorded image from one hour ago")
    func getRecordedImage() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let oneHourAgo = formatTimestamp(Date().addingTimeInterval(-3600))

        var params = GetRecordedImageParams()
        params.type = .preview
        params.timestampGte = oneHourAgo
        let result = try await toolkit.media.getRecordedImage(deviceId: cameraId, params: params)
        #expect(!result.imageData.isEmpty, "Expected non-empty recorded image data")
        #expect(result.contentType == "image/jpeg")
        #expect(result.imageData.count > 100, "Recorded image data too small")
    }

    @Test("Get recorded image with main stream type")
    func getRecordedImageMain() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let oneHourAgo = formatTimestamp(Date().addingTimeInterval(-3600))

        var params = GetRecordedImageParams()
        params.type = .main
        params.timestampGte = oneHourAgo
        let result = try await toolkit.media.getRecordedImage(deviceId: cameraId, params: params)
        #expect(!result.imageData.isEmpty, "Expected non-empty main recorded image")
        #expect(result.imageData.count > 100, "Main recorded image too small")
    }

    @Test("List media intervals for a camera")
    func listMediaIntervals() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let cameras = try await toolkit.cameras.list()
        #expect(!cameras.results.isEmpty)

        let cameraId = cameras.results[0].id
        let oneHourAgo = formatTimestamp(Date().addingTimeInterval(-3600))

        let params = ListMediaParams(
            deviceId: cameraId,
            type: .preview,
            mediaType: .video,
            startTimestamp: oneHourAgo
        )
        let result = try await toolkit.media.listMedia(params: params)
        #expect(result.results.count >= 0)

        if let interval = result.results.first {
            #expect(interval.deviceId == cameraId)
            #expect(!interval.startTimestamp.isEmpty)
            #expect(!interval.endTimestamp.isEmpty)
        }
    }

    // MARK: - User Tests

    @Test("Get current user returns user with email")
    func getCurrentUser() async throws {
        let creds = try LiveServiceTests.loadCredentials()
        let toolkit = await LiveServiceTests.makeToolkit(credentials: creds)

        let user = try await toolkit.users.getCurrentUser()
        #expect(!user.id.isEmpty)
        if let expectedEmail = creds.userEmail {
            #expect(user.email == expectedEmail)
        }
    }

    // MARK: - Auth Tests (destructive — must run last)

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

        // Refresh to get a valid token (earlier tests may have invalidated the original)
        try await toolkit.auth.refreshToken()

        let user = try await toolkit.users.getCurrentUser()
        #expect(!user.id.isEmpty)

        try await toolkit.auth.revokeToken()

        let token = await toolkit.authState.token
        #expect(token == nil, "Token should be nil after revoke")

        do {
            _ = try await toolkit.users.getCurrentUser()
            Issue.record("Expected authRequired error after revoke")
        } catch let error as EENError {
            #expect(error.code == .authRequired)
        }
    }
}
