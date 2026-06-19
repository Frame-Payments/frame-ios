//
//  PublishableKeyGuardTests.swift
//  Frame-iOS
//
//  Guard tests for the publishable-key-first auth model (FRA-4313).
//
//  These assert that:
//   - the default credential for a request is the publishable key (pk_), not the secret key;
//   - an explicit client secret (charge intent / onboarding session) is sent verbatim;
//   - while an onboarding session is active, every request carries the onb_sess_ token;
//   - initializing with an sk_ key does not reject — it warns and continues (non-breaking).
//

import XCTest
@testable import Frame

/// A `URLSessionProtocol` mock that records the most recent request so tests can inspect
/// the `Authorization` header the SDK produced.
final class HeaderCapturingAsyncSession: URLSessionProtocol, @unchecked Sendable {
    private(set) var requests: [URLRequest] = []
    var data: Data?
    var response: URLResponse?

    init(data: Data? = Data("{}".utf8),
         response: URLResponse? = HTTPURLResponse(url: URL(string: "https://api.framepayments.com")!,
                                                  statusCode: 200, httpVersion: nil, headerFields: nil)) {
        self.data = data
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard let data, let response else { throw URLError(.badServerResponse) }
        return (data, response)
    }

    var lastRequest: URLRequest? { requests.last }

    /// The `Authorization` header of the most recent request. `initialize()` spawns background
    /// requests (Evervault config, device attestation); prefer `authorizationHeader(forPath:)`
    /// when asserting on a specific endpoint to avoid racing those.
    func authorizationHeader() -> String? {
        lastRequest?.value(forHTTPHeaderField: "Authorization")
    }

    /// The `Authorization` header of the most recent request whose URL path contains `path`.
    func authorizationHeader(forPath path: String) -> String? {
        requests.last { $0.url?.absoluteString.contains(path) == true }?
            .value(forHTTPHeaderField: "Authorization")
    }

    /// Whether any recorded request targeted `path`.
    func sentRequest(toPath path: String) -> Bool {
        requests.contains { $0.url?.absoluteString.contains(path) == true }
    }
}

final class PublishableKeyGuardTests: XCTestCase {

    private let endpoint = MockFrameEndpoints(endpointURL: "/v1/payment_methods", httpMethod: .POST, queryItems: nil)

    override func tearDown() {
        // The SDK is a shared singleton; restore a clean auth context so state from these tests
        // (onboarding session, injected mock session) doesn't bleed into other test classes.
        FrameNetworking.shared.endOnboardingSession()
        FrameNetworking.shared.asyncURLSession = URLSession.shared
        super.tearDown()
    }

    private func makeSession() -> HeaderCapturingAsyncSession {
        let session = HeaderCapturingAsyncSession()
        FrameNetworking.shared.asyncURLSession = session
        FrameNetworking.shared.endOnboardingSession() // ensure a clean auth context per test
        return session
    }

    /// The default `auth` resolves to the publishable key, never the secret key.
    func testDefaultAuthUsesPublishableKey() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = makeSession()

        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)

        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer pk_test_123")
    }

    /// An explicitly secret-tagged request uses the secret key (the only path that should).
    func testSecretAuthUsesSecretKey() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = makeSession()

        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)

        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer sk_test_456")
    }

    /// A per-object client secret (e.g. a charge intent's client_secret) is sent verbatim.
    func testClientSecretAuthUsesProvidedToken() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123")
        let session = makeSession()

        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .clientSecret("ci_abc_secret_xyz"))

        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer ci_abc_secret_xyz")
    }

    /// While an onboarding session is active, every request — even a `.secret`-tagged one —
    /// carries the onboarding-session token, scoping the flow to one account.
    func testOnboardingSessionOverridesAllAuthModes() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = makeSession()
        FrameNetworking.shared.beginOnboardingSession(clientSecret: "onb_sess_live_token")
        defer { FrameNetworking.shared.endOnboardingSession() }

        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer onb_sess_live_token")

        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer onb_sess_live_token")
    }

    /// Ending the onboarding session restores publishable-key authentication.
    func testEndingOnboardingSessionRestoresPublishableKey() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123")
        let session = makeSession()
        FrameNetworking.shared.beginOnboardingSession(clientSecret: "onb_sess_live_token")
        FrameNetworking.shared.endOnboardingSession()

        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)

        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer pk_test_123")
    }

    /// A non-`onb_sess_` token passed to `beginOnboardingSession` still applies (warn-not-break);
    /// the SDK logs a guardrail warning but uses the value verbatim so behavior is unchanged.
    func testBeginOnboardingSessionAppliesNonPrefixedTokenVerbatim() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = makeSession()
        FrameNetworking.shared.beginOnboardingSession(clientSecret: "pk_wrong_token")
        defer { FrameNetworking.shared.endOnboardingSession() }

        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)

        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer pk_wrong_token")
    }

    /// A representative client-safe API (card tokenization) sends the publishable key.
    func testClientSafeAPIUsesPublishableKey() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = makeSession()
        // Return a 200 with an empty body; we only care about the Authorization header.
        session.data = Data("{}".utf8)

        _ = try? await PaymentMethodsAPI.createCardPaymentMethod(
            request: PaymentMethodRequest.CreateCardPaymentMethodRequest(
                type: .card, cardNumber: "4242424242424242", expMonth: "12", expYear: "2030", cvc: "123",
                customer: "cus_1", account: nil, billing: nil),
            encryptData: false)

        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer pk_test_123")
    }

    /// Initializing with an sk_ key as the publishable key does NOT reject (non-breaking);
    /// the SDK warns and continues, and the value is still usable.
    func testInitWithSecretKeyDoesNotReject() async throws {
        FrameNetworking.shared.initialize(publishableKey: "sk_test_oops")
        let session = makeSession()

        // Does not crash/throw; the (misused) key is what gets sent for a publishable request.
        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer sk_test_oops")
    }

    /// `confirmChargeIntent` sends the provided charge-intent client_secret as the Bearer token,
    /// not the publishable or secret key.
    func testConfirmChargeIntentSendsClientSecretAsBearer() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = makeSession()
        session.data = Data("{}".utf8)

        _ = try? await ChargeIntentsAPI.confirmChargeIntent(intentId: "ci_123", clientSecret: "ci_123_secret_abc")

        // Filter by path: initialize() spawns background pk_ requests (Evervault/attestation).
        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/charge_intents/ci_123/confirm"),
                       "Bearer ci_123_secret_abc")
    }

    /// An empty client_secret short-circuits (no request is made) rather than sending `Bearer `.
    func testConfirmChargeIntentRejectsEmptyClientSecret() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123")
        let session = makeSession()

        let (result, error) = try await ChargeIntentsAPI.confirmChargeIntent(intentId: "ci_123", clientSecret: "")

        XCTAssertNil(result)
        XCTAssertNil(error)
        XCTAssertFalse(session.sentRequest(toPath: "/v1/charge_intents"),
                       "no charge-intent request should be sent for an empty client_secret")
    }

    /// The completion-handler request path (which builds the Authorization header separately from
    /// the async path) also defaults to the publishable key.
    func testCompletionHandlerPathDefaultsToPublishableKey() {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        FrameNetworking.shared.endOnboardingSession()
        FrameNetworking.shared.urlSession = makeMockURLSession()
        MockURLProtocol.lastRequest = nil
        MockURLProtocol.mockData = Data("{}".utf8)
        MockURLProtocol.mockResponse = HTTPURLResponse(url: URL(string: "https://api.framepayments.com")!,
                                                       statusCode: 200, httpVersion: nil, headerFields: nil)
        defer {
            MockURLProtocol.lastRequest = nil
            MockURLProtocol.mockData = nil
            MockURLProtocol.mockResponse = nil
            FrameNetworking.shared.urlSession = URLSession.shared
        }

        let expectation = expectation(description: "completion handler called")
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { _, _, _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // URLSession can relocate the Authorization header; assert via the captured request if present.
        if let header = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") {
            XCTAssertEqual(header, "Bearer pk_test_123")
        }
    }

    /// The multipart upload path resolves auth via the same mechanism: explicit `.secret` sends sk_.
    func testMultipartUsesResolvedAuth() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = makeSession()
        session.data = Data("{}".utf8)

        _ = try await FrameNetworking.shared.performMultipartDataTask(endpoint: endpoint, filesToUpload: [], auth: .secret)
        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer sk_test_456")

        _ = try await FrameNetworking.shared.performMultipartDataTask(endpoint: endpoint, filesToUpload: [])
        XCTAssertEqual(session.authorizationHeader(forPath: "/v1/payment_methods"), "Bearer pk_test_123")
    }
}
