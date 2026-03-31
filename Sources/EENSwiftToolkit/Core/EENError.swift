import Foundation

/// Machine-readable error codes matching the TypeScript toolkit.
public enum ErrorCode: String, Codable, Sendable {
    case authRequired = "AUTH_REQUIRED"
    case authFailed = "AUTH_FAILED"
    case tokenExpired = "TOKEN_EXPIRED"
    case apiError = "API_ERROR"
    case networkError = "NETWORK_ERROR"
    case validationError = "VALIDATION_ERROR"
    case notFound = "NOT_FOUND"
    case forbidden = "FORBIDDEN"
    case rateLimited = "RATE_LIMITED"
    case serviceUnavailable = "SERVICE_UNAVAILABLE"
    case unknownError = "UNKNOWN_ERROR"
}

/// Error type for all EEN API operations.
public struct EENError: Error, Sendable {
    /// Machine-readable error code.
    public let code: ErrorCode

    /// Human-readable error message.
    public let message: String

    /// HTTP status code, if applicable.
    public let status: Int?

    /// Additional error details from the API response.
    public let details: [String: String]?

    public init(code: ErrorCode, message: String, status: Int? = nil, details: [String: String]? = nil) {
        self.code = code
        self.message = message
        self.status = status
        self.details = details
    }
}

extension EENError: LocalizedError {
    public var errorDescription: String? { message }
}

extension EENError: CustomStringConvertible {
    public var description: String {
        if let status {
            return "EENError(\(code.rawValue), status: \(status)): \(message)"
        }
        return "EENError(\(code.rawValue)): \(message)"
    }
}

/// Maps an HTTP status code to the appropriate `ErrorCode`.
func errorCode(forHTTPStatus status: Int) -> ErrorCode {
    switch status {
    case 401: return .authRequired
    case 403: return .forbidden
    case 404: return .notFound
    case 429: return .rateLimited
    case 503: return .serviceUnavailable
    default: return .apiError
    }
}
