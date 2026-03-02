import Foundation
import os

/// Internal debug logger for the toolkit.
enum EENDebug {
    private static let logger = Logger(subsystem: "com.een.api-toolkit", category: "EENApiToolkit")

    static var isEnabled = false

    static func log(_ message: String) {
        guard isEnabled else { return }
        logger.debug("[een-api-toolkit] \(message, privacy: .public)")
    }
}
