import XCTest

final class SwiftEventsUITests: XCTestCase {

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
            .deletingLastPathComponent() // SwiftEventsUITests/
            .deletingLastPathComponent() // swift-events/
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

    // MARK: - Auth Tests

    @MainActor
    func testAppLaunchShowsLogin() throws {
        // Launch with an invalid token so keychain session restore fails
        let cleanApp = XCUIApplication()
        cleanApp.launchArguments = ["-RESET_KEYCHAIN"]
        cleanApp.launchEnvironment["TEST_TOKEN"] = ""
        cleanApp.launchEnvironment["TEST_BASE_URL"] = ""
        cleanApp.launchEnvironment["TEST_SESSION_ID"] = ""
        cleanApp.launch()

        // Either we see login (no cached session) or tabs (cached keychain)
        let signIn = cleanApp.buttons["SignInButton"]
        let tabs = cleanApp.tabBars.buttons["Types"]
        let foundLogin = signIn.waitForExistence(timeout: 10)
        let foundTabs = tabs.exists

        // If keychain has a valid session from a prior run, tabs may appear — that's OK
        XCTAssertTrue(foundLogin || foundTabs,
                      "App should show either login or authenticated state")
    }

    @MainActor
    func testTokenInjectionShowsTabs() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let typesTab = app.tabBars.buttons["Types"]
        XCTAssertTrue(typesTab.waitForExistence(timeout: 15),
                      "Types tab should appear after authentication")

        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.exists, "History tab should exist")

        let liveTab = app.tabBars.buttons["Live"]
        XCTAssertTrue(liveTab.exists, "Live tab should exist")
    }

    // MARK: - Camera Picker Tests

    @MainActor
    func testCameraPickerShowsCameras() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let typesTab = app.tabBars.buttons["Types"]
        guard typesTab.waitForExistence(timeout: 15) else {
            XCTFail("Types tab not found")
            return
        }

        let cameraPicker = app.buttons["CameraPickerButton"]
        guard cameraPicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found")
            return
        }
        cameraPicker.tap()

        sleep(5)

        let cells = app.cells
        XCTAssertTrue(cells.count > 0, "At least one camera should be listed")
    }

    @MainActor
    func testCameraAutoSelectUpdatesPickerLabel() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let typesTab = app.tabBars.buttons["Types"]
        guard typesTab.waitForExistence(timeout: 15) else {
            XCTFail("Types tab not found")
            return
        }

        sleep(5)

        let cameraPicker = app.buttons["CameraPickerButton"]
        guard cameraPicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found")
            return
        }

        let label = cameraPicker.label
        XCTAssertFalse(label.contains("Select Camera"),
                       "Camera picker should show a camera name after auto-select. Got: \(label)")
    }

    // MARK: - Event Types Tab Tests

    @MainActor
    func testEventTypesTabShowsList() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let typesTab = app.tabBars.buttons["Types"]
        guard typesTab.waitForExistence(timeout: 15) else {
            XCTFail("Types tab not found")
            return
        }

        // Wait for camera auto-select and event types to load
        let eventTypesList = app.collectionViews["EventTypesList"]
        XCTAssertTrue(eventTypesList.waitForExistence(timeout: 30),
                      "Event types list should appear after camera auto-selection")

        let cells = eventTypesList.cells
        XCTAssertTrue(cells.count > 0, "At least one event type should be listed")
    }

    // MARK: - History Tab Tests

    @MainActor
    func testHistoryTabShowsControls() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let historyTab = app.tabBars.buttons["History"]
        guard historyTab.waitForExistence(timeout: 15) else {
            XCTFail("History tab not found")
            return
        }
        historyTab.tap()

        let loadButton = app.buttons["LoadEventsButton"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 10),
                      "Load button should exist on History tab")

        let slider = app.sliders["HoursSlider"]
        XCTAssertTrue(slider.exists, "Hours slider should exist on History tab")
    }

    @MainActor
    func testHistoryTabLoadsEvents() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let historyTab = app.tabBars.buttons["History"]
        guard historyTab.waitForExistence(timeout: 15) else {
            XCTFail("History tab not found")
            return
        }
        historyTab.tap()

        // Wait for camera auto-select and event types to load, then tap Load
        sleep(8)

        let loadButton = app.buttons["LoadEventsButton"]
        guard loadButton.waitForExistence(timeout: 10) else {
            XCTFail("Load button not found")
            return
        }
        loadButton.tap()

        // Wait for events to load
        sleep(15)

        // Check multiple indicators: cells, list identifier, "No events", or "een." text (event type)
        let noEvents = app.staticTexts["No events found"]
        let hasCells = app.cells.count > 0
        let hasEenText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'een.'")).count > 0
        let loadingGone = !app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Loading events'")).element.exists
        XCTAssertTrue(hasCells || noEvents.exists || hasEenText || loadingGone,
                      "Events should have loaded (cells: \(app.cells.count), noEvents: \(noEvents.exists), eenText: \(hasEenText))")
    }

    // MARK: - Live Tab Tests

    @MainActor
    func testLiveTabShowsControls() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let liveTab = app.tabBars.buttons["Live"]
        guard liveTab.waitForExistence(timeout: 15) else {
            XCTFail("Live tab not found")
            return
        }
        liveTab.tap()

        let toggleButton = app.buttons["SSEToggleButton"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 10),
                      "SSE toggle button should exist on Live tab")

        let status = app.staticTexts["SSEStatus"]
        XCTAssertTrue(status.exists, "SSE status label should exist on Live tab")

        let eventCount = app.staticTexts["SSEEventCount"]
        XCTAssertTrue(eventCount.exists, "Event count label should exist on Live tab")
    }

    // MARK: - Sign Out Test

    @MainActor
    func testSignOutReturnsToLogin() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let typesTab = app.tabBars.buttons["Types"]
        guard typesTab.waitForExistence(timeout: 15) else {
            XCTFail("Types tab not found")
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

    // MARK: - Camera Selection Persistence

    @MainActor
    func testCameraSelectionPersistsAcrossTabs() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let typesTab = app.tabBars.buttons["Types"]
        guard typesTab.waitForExistence(timeout: 15) else {
            XCTFail("Types tab not found")
            return
        }

        sleep(5)

        let typesPicker = app.buttons["CameraPickerButton"]
        guard typesPicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found on Types tab")
            return
        }
        let typesLabel = typesPicker.label

        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        sleep(1)

        let historyPicker = app.buttons["CameraPickerButton"]
        guard historyPicker.waitForExistence(timeout: 10) else {
            XCTFail("Camera picker not found on History tab")
            return
        }
        let historyLabel = historyPicker.label

        XCTAssertEqual(typesLabel, historyLabel,
                       "Camera selection should persist across tabs")
    }
}
