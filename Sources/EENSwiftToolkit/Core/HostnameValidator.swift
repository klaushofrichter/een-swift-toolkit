import Foundation

/// Validates hostnames against the EEN domain allowlist.
enum HostnameValidator {
    private static let allowedDomains = [".eagleeyenetworks.com", ".een.cloud"]
    // swiftlint:disable:next force_try
    private static let validHostnameRegex = try! NSRegularExpression(
        pattern: "^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)*$"
    )

    /// Returns `true` if the hostname is a valid EEN API hostname.
    static func isAllowed(_ hostname: String) -> Bool {
        let normalized = hostname.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return false }
        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        guard validHostnameRegex.firstMatch(in: normalized, range: range) != nil else {
            return false
        }
        return allowedDomains.contains { domain in
            normalized == String(domain.dropFirst()) || normalized.hasSuffix(domain)
        }
    }

    /// Extracts and validates the hostname from an `httpsBaseUrl` returned by the token endpoint.
    /// Returns the validated base URL or throws if the hostname is not allowed.
    static func validateBaseUrl(_ httpsBaseUrl: String) throws -> String {
        guard let url = URL(string: httpsBaseUrl), let host = url.host else {
            throw EENError(code: .validationError, message: "Invalid base URL: \(httpsBaseUrl)")
        }
        guard isAllowed(host) else {
            throw EENError(code: .validationError, message: "Hostname not in EEN allowlist: \(host)")
        }
        return httpsBaseUrl
    }
}
