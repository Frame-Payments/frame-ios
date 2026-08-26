//
//  ThreeDSecureChallengeViewTests.swift
//  Frame-iOS
//

#if canImport(UIKit)
import XCTest
import WebKit
@testable import Frame

/// The challenge sheet closes on a redirect to the API's callback, so the path it watches for has
/// to be the one the API actually builds. A mismatch leaves the cardholder stuck on the web view
/// after they have finished authenticating.
final class ThreeDSecureChallengeViewTests: XCTestCase {

    private func coordinator() -> ThreeDSecureChallengeView.Coordinator {
        ThreeDSecureChallengeView.Coordinator(
            returnURLPathComponent: FrameThreeDSecureChallengePresenter.callbackPathComponent,
            onFinish: {},
            onLoadFailure: { _ in })
    }

    /// The URL the API bakes into `challenge_url` as the Evervault `redirect` parameter,
    /// from `GET /v1/evervault/3ds/callback/:id`.
    func testRecognisesTheAPICallbackRedirect() {
        let url = URL(string: "https://api.framepayments.com/v1/evervault/3ds/callback/chg_abc123")

        XCTAssertTrue(coordinator().isReturn(url))
    }

    /// Shopify's callback is a different route (`evervault_3ds_callbacks`); matching it here
    /// would mean matching neither once the underscore form is gone.
    func testDoesNotMatchTheShopifyCallbackPath() {
        let url = URL(string: "https://api.framepayments.com/platforms/shopify/evervault_3ds_callbacks/chg_abc123")

        XCTAssertFalse(coordinator().isReturn(url))
    }

    /// The issuer's own pages must render rather than being taken for the finish signal.
    func testDoesNotMatchTheChallengePageItself() {
        let url = URL(string: "https://3ds.evervault.com/?team=t&app=a&session=s&redirect=https%3A%2F%2Fexample.com")

        XCTAssertFalse(coordinator().isReturn(url))
    }

    func testNilURLIsNotAReturn() {
        XCTAssertFalse(coordinator().isReturn(nil))
    }

    /// A redirect and a teardown can both arrive; the second must not re-fire the callback.
    func testFinishIsReportedOnlyOnce() {
        var finishCount = 0
        let coordinator = ThreeDSecureChallengeView.Coordinator(
            returnURLPathComponent: FrameThreeDSecureChallengePresenter.callbackPathComponent,
            onFinish: { finishCount += 1 },
            onLoadFailure: { _ in XCTFail("a finished challenge is not a load failure") })

        let url = URL(string: "https://api.framepayments.com/v1/evervault/3ds/callback/chg_abc123")!
        let webView = WKWebView()

        for _ in 0..<2 {
            coordinator.webView(webView,
                                decidePolicyFor: StubNavigationAction(url: url),
                                decisionHandler: { _ in })
        }

        XCTAssertEqual(finishCount, 1)
    }
}

/// `WKNavigationAction.request` is read-only, so the request comes from an override.
private final class StubNavigationAction: WKNavigationAction {
    private let stubbedRequest: URLRequest

    init(url: URL) {
        self.stubbedRequest = URLRequest(url: url)
        super.init()
    }

    override var request: URLRequest { stubbedRequest }
}
#endif
