import XCTest

final class SwiftUsersUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Pass test credentials via environment variables.
        // These are read by SwiftUsersApp.injectFromEnvironment().
        // Set them in the scheme or via xcodebuild launch args.
        let env = ProcessInfo.processInfo.environment
        if let token = env["TEST_TOKEN"] {
            app.launchEnvironment["TEST_TOKEN"] = token
        }
        if let baseUrl = env["TEST_BASE_URL"] {
            app.launchEnvironment["TEST_BASE_URL"] = baseUrl
        }
        if let sessionId = env["TEST_SESSION_ID"] {
            app.launchEnvironment["TEST_SESSION_ID"] = sessionId
        }
        if let expiresIn = env["TEST_EXPIRES_IN"] {
            app.launchEnvironment["TEST_EXPIRES_IN"] = expiresIn
        }
        if let email = env["TEST_USER_EMAIL"] {
            app.launchEnvironment["TEST_USER_EMAIL"] = email
        }
    }

    /// Verify that after loading users, there is no "Load More" button
    /// (meaning all users fit on one page and pagination tokens are properly nil).
    func testUsersPageHasNoLoadMoreButton() throws {
        app.launch()

        // Wait for authentication to complete and tabs to appear
        let usersTab = app.tabBars.buttons["Users"]
        XCTAssertTrue(usersTab.waitForExistence(timeout: 15),
                      "Users tab should appear after authentication")

        // Tap the Users tab
        usersTab.tap()

        // Wait for the user list to load (look for the navigation title)
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
