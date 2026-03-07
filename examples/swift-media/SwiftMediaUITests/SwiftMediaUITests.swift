import XCTest

final class SwiftMediaUITests: XCTestCase {

    private var app: XCUIApplication!
    private var credentials: [String: Any]?

    private var hasCredentials: Bool {
        guard let creds = credentials else { return false }
        return creds["accessToken"] != nil && creds["httpsBaseUrl"] != nil
    }

    private static func loadCredentials() -> [String: Any]? {
        let env = ProcessInfo.processInfo.environment
        if let token = env["TEST_TOKEN"],
           let baseUrl = env["TEST_BASE_URL"],
           let sessionId = env["TEST_SESSION_ID"] {
            return [
                "accessToken": token,
                "httpsBaseUrl": baseUrl,
                "sessionId": sessionId,
                "expiresIn": env["TEST_EXPIRES_IN"] ?? "3600",
                "userEmail": env["TEST_USER_EMAIL"] ?? ""
            ]
        }

        let projectDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // SwiftMediaUITests/
            .deletingLastPathComponent() // swift-media/
        let toolkitDir = projectDir
            .deletingLastPathComponent() // examples/
            .deletingLastPathComponent() // EENApiToolkit/

        let candidatePaths = [
            projectDir.appendingPathComponent("ui-test-credentials.json"),
            toolkitDir.appendingPathComponent("test-credentials.json")
        ]

        for path in candidatePaths {
            if let data = try? Data(contentsOf: path),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["accessToken"] != nil {
                return json
            }
        }
        return nil
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        credentials = Self.loadCredentials()
        app = XCUIApplication()

        if let creds = credentials {
            if let token = creds["accessToken"] as? String {
                app.launchEnvironment["TEST_TOKEN"] = token
            }
            if let baseUrl = creds["httpsBaseUrl"] as? String {
                app.launchEnvironment["TEST_BASE_URL"] = baseUrl
            }
            if let sessionId = creds["sessionId"] as? String {
                app.launchEnvironment["TEST_SESSION_ID"] = sessionId
            }
            if let email = creds["userEmail"] as? String {
                app.launchEnvironment["TEST_USER_EMAIL"] = email
            }
            if let ttl = creds["expiresIn"] as? String {
                app.launchEnvironment["TEST_EXPIRES_IN"] = ttl
            } else if let ttl = creds["expiresIn"] as? Int {
                app.launchEnvironment["TEST_EXPIRES_IN"] = String(ttl)
            }
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tests

    /// Without credentials the app should show the login screen.
    @MainActor
    func testAppLaunchShowsLogin() throws {
        let cleanApp = XCUIApplication()
        cleanApp.launch()

        let signIn = cleanApp.buttons["SignInButton"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 10),
                      "Sign In button should be visible without credentials")
    }

    /// Inject token -> app should authenticate and show tabs.
    @MainActor
    func testTokenInjectionShowsTabs() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        XCTAssertTrue(liveTab.waitForExistence(timeout: 15),
                      "Live tab should appear after authentication")

        let recordedTab = app.tabBars.buttons["Recorded"]
        XCTAssertTrue(recordedTab.exists, "Recorded tab should exist")

        let videoTab = app.tabBars.buttons["Video"]
        XCTAssertTrue(videoTab.exists, "Video tab should exist")
    }

    /// Live tab should show the camera picker and refresh controls.
    @MainActor
    func testLiveTabShowsControls() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        let cameraPicker = app.buttons["CameraPickerButton"]
        XCTAssertTrue(cameraPicker.waitForExistence(timeout: 10),
                      "Camera picker should be visible on Live tab")

        let refreshButton = app.buttons["RefreshButton"]
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5),
                      "Refresh button should exist on Live tab")
    }

    /// Recorded tab should show time picker and navigation buttons.
    @MainActor
    func testRecordedTabShowsControls() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let recordedTab = app.tabBars.buttons["Recorded"]
        guard recordedTab.waitForExistence(timeout: 15) else {
            XCTFail("Recorded tab not found")
            return
        }
        recordedTab.tap()

        let goButton = app.buttons["GoButton"]
        XCTAssertTrue(goButton.waitForExistence(timeout: 10),
                      "Go button should exist on Recorded tab")

        let prevButton = app.buttons["PrevButton"]
        XCTAssertTrue(prevButton.exists, "Previous button should exist")

        let nextButton = app.buttons["NextButton"]
        XCTAssertTrue(nextButton.exists, "Next button should exist")
    }

    /// Video tab should show time picker and Go button.
    @MainActor
    func testVideoTabShowsControls() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let videoTab = app.tabBars.buttons["Video"]
        guard videoTab.waitForExistence(timeout: 15) else {
            XCTFail("Video tab not found")
            return
        }
        videoTab.tap()

        let goButton = app.buttons["VideoGoButton"]
        XCTAssertTrue(goButton.waitForExistence(timeout: 10),
                      "Go button should exist on Video tab")
    }

    /// Camera picker should open and show a list of cameras.
    @MainActor
    func testCameraPickerShowsCameras() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        let cameraPicker = app.buttons["CameraPickerButton"]
        guard cameraPicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found")
            return
        }
        cameraPicker.tap()

        // Wait for camera list to load
        sleep(5)

        let cells = app.cells
        XCTAssertTrue(cells.count > 0, "At least one camera should be listed")
    }

    /// Live tab should load and display an image after camera selection.
    @MainActor
    func testLiveImageLoads() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        // Wait for camera auto-select and live image fetch
        let liveImage = app.images["LiveImage"]
        XCTAssertTrue(liveImage.waitForExistence(timeout: 30),
                      "Live image should appear after camera auto-selection")
    }

    /// Live tab should show a timestamp after image loads.
    @MainActor
    func testLiveTimestampAppears() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        let timestamp = app.staticTexts["LiveTimestamp"]
        XCTAssertTrue(timestamp.waitForExistence(timeout: 30),
                      "Live timestamp should appear after image loads")
    }

    /// Auto-refresh toggle should exist on Live tab.
    @MainActor
    func testAutoRefreshToggleExists() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        let toggle = app.switches["AutoRefreshToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10),
                      "Auto-refresh toggle should exist on Live tab")
    }

    /// Camera picker should show selected camera name after selection.
    @MainActor
    func testCameraSelectionUpdatesPickerLabel() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        // Wait for camera auto-select
        sleep(5)

        let cameraPicker = app.buttons["CameraPickerButton"]
        guard cameraPicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found")
            return
        }

        // After auto-select, the button label should no longer say "Select Camera"
        let label = cameraPicker.label
        XCTAssertFalse(label.contains("Select Camera"),
                       "Camera picker should show a camera name, not 'Select Camera'. Got: \(label)")
    }

    /// Recorded tab should load a preview image when Go is tapped.
    @MainActor
    func testRecordedPreviewImageLoads() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let recordedTab = app.tabBars.buttons["Recorded"]
        guard recordedTab.waitForExistence(timeout: 15) else {
            XCTFail("Recorded tab not found")
            return
        }
        recordedTab.tap()

        // Wait for camera auto-select
        sleep(3)

        let goButton = app.buttons["GoButton"]
        guard goButton.waitForExistence(timeout: 10) else {
            XCTFail("Go button not found")
            return
        }
        goButton.tap()

        // Either a preview image or "Image not available" should appear
        let previewImage = app.images["PreviewImage"]
        let unavailable = app.staticTexts["Image not available"]
        let found = previewImage.waitForExistence(timeout: 30)
            || unavailable.waitForExistence(timeout: 5)
        XCTAssertTrue(found,
                      "Either a preview image or 'Image not available' should appear after tapping Go")
    }

    /// Recorded tab should show Now button and it should work.
    @MainActor
    func testRecordedNowButton() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let recordedTab = app.tabBars.buttons["Recorded"]
        guard recordedTab.waitForExistence(timeout: 15) else {
            XCTFail("Recorded tab not found")
            return
        }
        recordedTab.tap()

        let nowButton = app.buttons["Now"]
        XCTAssertTrue(nowButton.waitForExistence(timeout: 10),
                      "Now button should exist on Recorded tab")
    }

    /// Video tab should show play and pause buttons.
    @MainActor
    func testVideoPlayPauseButtons() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let videoTab = app.tabBars.buttons["Video"]
        guard videoTab.waitForExistence(timeout: 15) else {
            XCTFail("Video tab not found")
            return
        }
        videoTab.tap()

        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 10),
                      "Play button should exist on Video tab")

        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.exists, "Pause button should exist on Video tab")
    }

    /// Video tab should show Now button.
    @MainActor
    func testVideoNowButton() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let videoTab = app.tabBars.buttons["Video"]
        guard videoTab.waitForExistence(timeout: 15) else {
            XCTFail("Video tab not found")
            return
        }
        videoTab.tap()

        let nowButton = app.buttons["Now"]
        XCTAssertTrue(nowButton.waitForExistence(timeout: 10),
                      "Now button should exist on Video tab")
    }

    /// Sign out button should exist and return to login screen.
    @MainActor
    func testSignOutReturnsToLogin() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        let signOut = app.buttons["SignOutButton"]
        guard signOut.waitForExistence(timeout: 10) else {
            XCTFail("Sign Out button not found")
            return
        }
        signOut.tap()

        let signIn = app.buttons["SignInButton"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 15),
                      "Sign In button should appear after sign out")
    }

    /// Camera picker should persist selection across tabs.
    @MainActor
    func testCameraSelectionPersistsAcrossTabs() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }

        // Wait for camera auto-select
        sleep(5)

        // Get camera name on Live tab
        let livePicker = app.buttons["CameraPickerButton"]
        guard livePicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found on Live tab")
            return
        }
        let liveLabel = livePicker.label

        // Switch to Recorded tab
        let recordedTab = app.tabBars.buttons["Recorded"]
        recordedTab.tap()
        sleep(1)

        let recordedPicker = app.buttons["CameraPickerButton"]
        guard recordedPicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found on Recorded tab")
            return
        }
        let recordedLabel = recordedPicker.label

        XCTAssertEqual(liveLabel, recordedLabel,
                       "Camera selection should persist across tabs")
    }
}
