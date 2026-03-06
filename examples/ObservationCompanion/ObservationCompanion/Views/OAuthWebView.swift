import Combine
import SwiftUI
import WebKit
import EENApiToolkit

/// Manages a single WKWebView instance that can be pre-loaded in the view hierarchy
/// (hidden) and then re-parented into a sheet once the user taps "Sign In".
@MainActor
class OAuthWebViewManager: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var isPageLoaded = false

    let redirectUri: String
    var onCallback: ((String, String?) -> Void)?
    var onError: ((String) -> Void)?

    private(set) var webView: WKWebView
    private var callbackHandled = false

    init(redirectUri: String) {
        self.redirectUri = redirectUri
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.navigationDelegate = self
    }

    func loadAuthUrl(_ url: URL) {
        callbackHandled = false
        isPageLoaded = false
        webView.load(URLRequest(url: url))
    }

    /// Reset for a fresh session (e.g. after cancel).
    func reset(authUrl: URL) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let newWebView = WKWebView(frame: webView.frame, configuration: config)
        newWebView.autoresizingMask = webView.autoresizingMask
        newWebView.navigationDelegate = self

        // Swap in place so the hosting UIView picks it up
        if let parent = webView.superview {
            parent.insertSubview(newWebView, belowSubview: webView)
            webView.removeFromSuperview()
        }
        webView = newWebView
        callbackHandled = false
        isPageLoaded = false
        webView.load(URLRequest(url: authUrl))
    }

    // MARK: - WKNavigationDelegate

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.isPageLoaded = true
        }
    }

    nonisolated func webView(_ webView: WKWebView,
                  decidePolicyFor navigationAction: WKNavigationAction,
                  decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString
        let normalizedRedirect = redirectUri.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if urlString.hasPrefix(normalizedRedirect) {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                let state = components?.queryItems?.first(where: { $0.name == "state" })?.value
                decisionHandler(.cancel)
                Task { @MainActor in
                    guard !self.callbackHandled else { return }
                    self.callbackHandled = true
                    self.onCallback?(code, state)
                }
                return
            }
            if let error = components?.queryItems?.first(where: { $0.name == "error" })?.value {
                let desc = components?.queryItems?.first(where: { $0.name == "error_description" })?.value
                decisionHandler(.cancel)
                Task { @MainActor in
                    guard !self.callbackHandled else { return }
                    self.callbackHandled = true
                    self.onError?(desc ?? error)
                }
                return
            }
        }

        decisionHandler(.allow)
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        Task { @MainActor in
            guard !self.callbackHandled else { return }
            self.onError?(error.localizedDescription)
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        if let failingUrl = (error as NSError).userInfo["NSErrorFailingURLKey"] as? URL {
            let components = URLComponents(url: failingUrl, resolvingAgainstBaseURL: false)
            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                let state = components?.queryItems?.first(where: { $0.name == "state" })?.value
                Task { @MainActor in
                    guard !self.callbackHandled else { return }
                    self.callbackHandled = true
                    self.onCallback?(code, state)
                }
                return
            }
        }
        Task { @MainActor in
            guard !self.callbackHandled else { return }
            self.onError?(error.localizedDescription)
        }
    }
}

// MARK: - Hidden host: places the web view in the view tree (invisible) so it renders

struct OAuthWebViewHidden: UIViewRepresentable {
    let manager: OAuthWebViewManager

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        let wv = manager.webView
        wv.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        wv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(wv)
        container.clipsToBounds = true
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // If the manager swapped the webView (after reset), update the container
        let wv = manager.webView
        if wv.superview !== uiView {
            for sub in uiView.subviews { sub.removeFromSuperview() }
            wv.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
            wv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            uiView.addSubview(wv)
        }
    }
}

// MARK: - Sheet host: re-parents the web view into the visible sheet

struct OAuthWebViewSheet: UIViewControllerRepresentable {
    let manager: OAuthWebViewManager

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        return vc
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        let wv = manager.webView
        if wv.superview !== vc.view {
            wv.removeFromSuperview()
            wv.frame = vc.view.bounds
            wv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            vc.view.addSubview(wv)
        }
    }
}
