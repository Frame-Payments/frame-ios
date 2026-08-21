//
//  ThreeDSecureChallengeView.swift
//  Frame-iOS
//

#if canImport(UIKit)
import SwiftUI
import WebKit

/// Hosts an issuer-controlled 3D Secure challenge.
///
/// The page is served by the card network, so the code the cardholder enters never reaches
/// this app — the reason for a web view rather than native digit fields. The view reports only
/// that the challenge finished; the Frame API decides whether the charge succeeded.
struct ThreeDSecureChallengeView: UIViewRepresentable {
    /// The issuer challenge page to load.
    let challengeURL: URL
    /// The redirect that signals the challenge is over.
    let returnURLPrefix: String
    /// Called once, when the page redirects to ``returnURLPrefix``.
    let onFinish: () -> Void
    /// Called if the page fails to load.
    let onLoadFailure: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(returnURLPrefix: returnURLPrefix, onFinish: onFinish, onLoadFailure: onLoadFailure)
    }

    func makeUIView(context: Context) -> WKWebView {
        // Keeps issuer cookies out of the host app's shared storage.
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: challengeURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(returnURLPrefix: returnURLPrefix, onFinish: onFinish, onLoadFailure: onLoadFailure)
    }

    /// Watches for the terminal redirect and reports it exactly once.
    final class Coordinator: NSObject, WKNavigationDelegate {
        private var returnURLPrefix: String
        private var onFinish: () -> Void
        private var onLoadFailure: (Error) -> Void
        /// A redirect and a load failure can both arrive during teardown.
        private var hasReported = false

        init(returnURLPrefix: String, onFinish: @escaping () -> Void, onLoadFailure: @escaping (Error) -> Void) {
            self.returnURLPrefix = returnURLPrefix
            self.onFinish = onFinish
            self.onLoadFailure = onLoadFailure
        }

        func update(returnURLPrefix: String, onFinish: @escaping () -> Void, onLoadFailure: @escaping (Error) -> Void) {
            self.returnURLPrefix = returnURLPrefix
            self.onFinish = onFinish
            self.onLoadFailure = onLoadFailure
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url?.absoluteString,
                  url.hasPrefix(returnURLPrefix) else {
                return decisionHandler(.allow)
            }

            // The return URL is a signal, not a page to render.
            decisionHandler(.cancel)
            report { $0.onFinish() }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report { $0.onLoadFailure(error) }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report { $0.onLoadFailure(error) }
        }

        private func report(_ body: (Coordinator) -> Void) {
            guard !hasReported else { return }
            hasReported = true
            body(self)
        }
    }
}
#endif
