import XCTest

final class SwiftUsersUITests: XCTestCase {

    private var app: XCUIApplication!
    private var credentials: [String: Any]?

    /// Whether live credentials are available for injection.
    private var hasCredentials: Bool {
        guard let creds = credentials else { return false }
        return creds["accessToken"] != nil && creds["httpsBaseUrl"] != nil
    }

    /// Load credentials from environment variables or from a credentials file
    /// written by run-ui-tests.sh next to the project.
    private static func loadCredentials() -> [String: Any]? {
        // Try environment variables first
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

        // Try file-based credentials (reliable with xcodebuild)
        let projectDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // SwiftUsersUITests/
            .deletingLastPathComponent() // swift-users/
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

        // Inject credentials as the env vars the app expects
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

        // Should show the Sign In button
        let signIn = cleanApp.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign In'")).firstMatch
        XCTAssertTrue(signIn.waitForExistence(timeout: 10), "Sign In button should be visible without credentials")
    }

    /// Inject token -> app should authenticate and show the tab bar.
    @MainActor
    func testTokenInjectionShowsTabs() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let usersTab = app.tabBars.buttons["Users"]
        XCTAssertTrue(usersTab.waitForExistence(timeout: 15),
                      "Users tab should appear after authentication")
    }

    /// After authentication, the Profile tab should show user info.
    @MainActor
    func testProfileTabShowsUserInfo() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        // Profile tab is shown by default
        let profileNav = app.navigationBars["My Profile"]
        XCTAssertTrue(profileNav.waitForExistence(timeout: 15),
                      "My Profile navigation bar should appear")
    }

    /// The Users tab should load and show a list of users.
    @MainActor
    func testUsersTabShowsUserList() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let usersTab = app.tabBars.buttons["Users"]
        guard usersTab.waitForExistence(timeout: 15) else {
            XCTFail("Users tab not found")
            return
        }
        usersTab.tap()

        let navBar = app.navigationBars["Users"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 15),
                      "Users navigation bar should appear")

        // Wait for the list to load
        sleep(3)

        // Should have at least one user cell visible
        let cells = app.cells
        XCTAssertTrue(cells.count > 0, "At least one user should be listed")
    }

    /// Verify "Load More" button does NOT exist when all users fit on one page.
    @MainActor
    func testUsersPageHasNoLoadMoreButton() throws {
        try XCTSkipUnless(hasCredentials, "Skipping: no TEST_TOKEN set")

        app.launch()

        let usersTab = app.tabBars.buttons["Users"]
        XCTAssertTrue(usersTab.waitForExistence(timeout: 15),
                      "Users tab should appear after authentication")

        usersTab.tap()

        let navBar = app.navigationBars["Users"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 15),
                      "Users navigation bar should appear")

        // Give the list time to fully load
        sleep(3)

        // Verify "Load More" button does NOT exist
        let loadMoreButton = app.buttons["LoadMoreButton"]
        XCTAssertFalse(loadMoreButton.exists,
                       "Load More button should not be visible when all users fit on one page")
    }
}
