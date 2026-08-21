//
//  ThreeDSecureChallengeView.swift
//  Frame-iOS
//

#if canImport(UIKit)
import SwiftUI
import WebKit

/// Hosts an issuer-controlled 3D Secure challenge.
///
/// The challenge page is served by the card network's directory server, and the code the
/// cardholder enters is never exposed to this app — that is the point of loading it in a web
/// view rather than collecting the digits natively. Nothing here reads, stores, or forwards
/// the page's contents.
///
/// The view reports only that the challenge finished. Whether the charge succeeded is decided
/// by the Frame API, which the caller polls afterwards.
struct ThreeDSecureChallengeView: UIViewRepresentable {
    /// The issuer challenge page to load.
    let challengeURL: URL
    /// The redirect that signals the challenge is over.
    let returnURLPrefix: String
    /// Called once, when the challenge page redirects to ``returnURLPrefix``.
    let onFinish: () -> Void
    /// Called if the challenge page itself fails to load.
    let onLoadFailure: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(returnURLPrefix: returnURLPrefix, onFinish: onFinish, onLoadFailure: onLoadFailure)
    }

    func makeUIView(context: Context) -> WKWebView {
        // A non-persistent store keeps issuer cookies out of the host app's shared storage.
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

    /// Watches for the challenge's terminal redirect and reports it exactly once.
    final class Coordinator: NSObject, WKNavigationDelegate {
        private var returnURLPrefix: String
        private var onFinish: () -> Void
        private var onLoadFailure: (Error) -> Void
        /// Guards against a second report: a redirect and a load failure can both arrive during
        /// teardown, and the caller's continuation must be resumed only once.
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
