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
    /// The path component of the redirect that signals the challenge is over.
    let returnURLPathComponent: String
    /// Called once, when the page redirects to ``returnURLPathComponent``.
    let onFinish: () -> Void
    /// Called if the page fails to load.
    let onLoadFailure: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(returnURLPathComponent: returnURLPathComponent, onFinish: onFinish, onLoadFailure: onLoadFailure)
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
        context.coordinator.update(returnURLPathComponent: returnURLPathComponent, onFinish: onFinish, onLoadFailure: onLoadFailure)
    }

    /// Watches for the terminal redirect and reports it exactly once.
    final class Coordinator: NSObject, WKNavigationDelegate {
        private var returnURLPathComponent: String
        private var onFinish: () -> Void
        private var onLoadFailure: (Error) -> Void
        /// A redirect and a load failure can both arrive during teardown.
        private var hasReported = false

        init(returnURLPathComponent: String, onFinish: @escaping () -> Void, onLoadFailure: @escaping (Error) -> Void) {
            self.returnURLPathComponent = returnURLPathComponent
            self.onFinish = onFinish
            self.onLoadFailure = onLoadFailure
        }

        func update(returnURLPathComponent: String, onFinish: @escaping () -> Void, onLoadFailure: @escaping (Error) -> Void) {
            self.returnURLPathComponent = returnURLPathComponent
            self.onFinish = onFinish
            self.onLoadFailure = onLoadFailure
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard isReturn(navigationAction.request.url) else {
                return decisionHandler(.allow)
            }

            // The return URL is a signal, not a page to render.
            decisionHandler(.cancel)
            report { $0.onFinish() }
        }

        /// The issuer redirects through a server that answers the callback with an empty 200, so
        /// the finish can surface as a completed response rather than a navigation to cancel.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            guard isReturn(navigationResponse.response.url) else {
                return decisionHandler(.allow)
            }

            decisionHandler(.cancel)
            report { $0.onFinish() }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report { $0.onLoadFailure(error) }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // Cancelling the return navigation surfaces here as a cancellation, which is the
            // challenge finishing rather than failing to load.
            if (error as NSError).code == NSURLErrorCancelled { return }
            report { $0.onLoadFailure(error) }
        }

        /// Internal rather than private so the path match is testable without a live web view.
        func isReturn(_ url: URL?) -> Bool {
            url?.absoluteString.contains(returnURLPathComponent) ?? false
        }

        private func report(_ body: (Coordinator) -> Void) {
            guard !hasReported else { return }
            hasReported = true
            body(self)
        }
    }
}
#endif
