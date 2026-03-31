import Testing
@testable import EENSwiftToolkit

@Suite("EENError Tests")
struct EENErrorTests {

    @Test("Error code mapping from HTTP status")
    func errorCodeMapping() {
        #expect(errorCode(forHTTPStatus: 401) == .authRequired)
        #expect(errorCode(forHTTPStatus: 403) == .forbidden)
        #expect(errorCode(forHTTPStatus: 404) == .notFound)
        #expect(errorCode(forHTTPStatus: 429) == .rateLimited)
        #expect(errorCode(forHTTPStatus: 503) == .serviceUnavailable)
        #expect(errorCode(forHTTPStatus: 500) == .apiError)
        #expect(errorCode(forHTTPStatus: 502) == .apiError)
    }

    @Test("Error description formatting")
    func errorDescription() {
        let error = EENError(code: .authRequired, message: "Not logged in", status: 401)
        #expect(error.description.contains("AUTH_REQUIRED"))
        #expect(error.description.contains("401"))
        #expect(error.description.contains("Not logged in"))
    }

    @Test("Error without status code")
    func errorWithoutStatus() {
        let error = EENError(code: .networkError, message: "Connection failed")
        #expect(error.status == nil)
        #expect(error.description.contains("NETWORK_ERROR"))
    }

    @Test("ErrorCode raw values match TypeScript")
    func errorCodeRawValues() {
        #expect(ErrorCode.authRequired.rawValue == "AUTH_REQUIRED")
        #expect(ErrorCode.authFailed.rawValue == "AUTH_FAILED")
        #expect(ErrorCode.tokenExpired.rawValue == "TOKEN_EXPIRED")
        #expect(ErrorCode.apiError.rawValue == "API_ERROR")
        #expect(ErrorCode.networkError.rawValue == "NETWORK_ERROR")
        #expect(ErrorCode.validationError.rawValue == "VALIDATION_ERROR")
        #expect(ErrorCode.notFound.rawValue == "NOT_FOUND")
        #expect(ErrorCode.forbidden.rawValue == "FORBIDDEN")
        #expect(ErrorCode.rateLimited.rawValue == "RATE_LIMITED")
        #expect(ErrorCode.serviceUnavailable.rawValue == "SERVICE_UNAVAILABLE")
        #expect(ErrorCode.unknownError.rawValue == "UNKNOWN_ERROR")
    }
}
