import AuthenticationServices
import Foundation

/// Wraps `ASWebAuthenticationSession` for OAuth browser-based authentication on iOS.
@MainActor
public final class OAuthWebSession: NSObject {
    private var session: ASWebAuthenticationSession?

    /// Present the OAuth login page and return the callback URL containing the authorization code.
    ///
    /// - Parameters:
    ///   - url: The OAuth authorization URL from `AuthManager.getAuthUrl()`.
    ///   - callbackScheme: The custom URL scheme for your app (e.g., "myapp").
    /// - Returns: The callback URL containing `code` and `state` query parameters.
    public func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: EENError(
                        code: .authFailed,
                        message: "Authentication cancelled or failed: \(error.localizedDescription)"
                    ))
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: EENError(
                        code: .authFailed,
                        message: "No callback URL received"
                    ))
                    return
                }
                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            self.session = session

            if !session.start() {
                continuation.resume(throwing: EENError(
                    code: .authFailed,
                    message: "Failed to start authentication session"
                ))
            }
        }
    }

    /// Extract the authorization code and state from a callback URL.
    public static func parseCallback(url: URL) -> (code: String, state: String?)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        let state = components.queryItems?.first(where: { $0.name == "state" })?.value
        return (code, state)
    }
}

extension OAuthWebSession: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        // Find the key window from connected scenes
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        return windowScene?.windows.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
