//
//  PhoneOTPRetryTests.swift
//  Frame-iOS
//
//  Covers the phone-OTP failure paths: the Twilio fallback the backend routes a re-create to
//  after a failed Prove attempt, a confirm that never reaches the network reporting failure
//  rather than advancing the flow, and a dismissed Prove sheet reading as a deliberate cancel.
//

import XCTest
@testable import Frame
@testable import FrameOnboarding

/// Returns a queued response per request, so a test can script a multi-call sequence such as
/// create → create. Falls back to the last entry once the queue drains.
private final class ScriptedURLSession: URLSessionProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var bodies: [String]
    private(set) var requestCount = 0

    init(bodies: [String]) {
        self.bodies = bodies
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.lock()
        defer { lock.unlock() }
        requestCount += 1
        let body = bodies.count > 1 ? bodies.removeFirst() : (bodies.first ?? "{}")
        let response = HTTPURLResponse(url: request.url ?? URL(string: "https://api.framepayments.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
        return (Data(body.utf8), response)
    }
}

@MainActor
final class PhoneOTPRetryTests: XCTestCase {

    override func tearDown() {
        FrameNetworking.shared.asyncURLSession = URLSession.shared
        FrameNetworking.shared.endOnboardingSession()
        super.tearDown()
    }

    private func makeViewModel() -> OnboardingContainerViewModel {
        FrameNetworking.shared.endOnboardingSession()
        return OnboardingContainerViewModel(accountId: "acct_123", requiredCapabilities: [])
    }

    // MARK: - Create response

    /// `provider` is the authoritative path signal, so it has to survive decoding — the flow
    /// previously inferred the path purely from `prove_auth_token` presence.
    func testCreateResponseDecodesProvider() throws {
        let json = """
        {"id":"ver_1","type":"phone","status":"pending","provider":"twilio"}
        """
        let response = try FrameNetworking.shared.jsonDecoder.decode(
            PhoneOTPVerificationCreateResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.provider, "twilio")
        XCTAssertNil(response.proveAuthToken)
    }

    /// A create that omits `provider` must still decode — the field is absent on older responses
    /// and the flow must not fail closed on it.
    func testCreateResponseDecodesWithoutProvider() throws {
        let json = """
        {"id":"ver_1","type":"phone","status":"pending","prove_auth_token":"jwt"}
        """
        let response = try FrameNetworking.shared.jsonDecoder.decode(
            PhoneOTPVerificationCreateResponse.self, from: Data(json.utf8))

        XCTAssertNil(response.provider)
        XCTAssertEqual(response.proveAuthToken, "jwt")
    }

    // MARK: - Twilio fallback after a failed Prove attempt

    /// The recovery the backend pins end to end: a failed Prove attempt re-creates, and the
    /// backend routes that second create to Twilio (no `prove_auth_token`). The flow must adopt
    /// the new verification so the applicant lands on code entry instead of the dead phone form.
    ///
    /// Prove is not driven here — the real SDK can't run in a unit test — so the fallback is
    /// exercised through the same entry point with a create that returns no token, standing in
    /// for the post-failure re-create.
    func testFallbackCreateAdoptsTwilioVerification() async {
        let viewModel = makeViewModel()
        FrameNetworking.shared.asyncURLSession = ScriptedURLSession(bodies: [
            #"{"id":"ver_twilio","type":"phone","status":"pending","provider":"twilio"}"#
        ])

        await viewModel.sendOTPVerification(phoneNumber: "+15551234567", dateOfBirth: "1990-01-15")

        XCTAssertEqual(viewModel.pendingTwilioVerificationId, "ver_twilio",
                       "a Twilio create must leave the flow ready to confirm a typed code")
        XCTAssertEqual(viewModel.pendingTwilioVerificationAccountId, "acct_123")
        XCTAssertNil(viewModel.proveUserInfo, "no code has been confirmed yet")
    }

    /// `submitProveOTP` lowers `showProveOTPEntry` to dismiss the sheet *before* Prove judges the
    /// code, so at failure time the sheet is already gone. The fallback must therefore key off
    /// "was an OTP requested", not off the sheet being up — reading the latter would skip the
    /// swap in exactly the case it exists for.
    func testSheetIsAlreadyDismissedWhenProveJudgesTheSubmittedCode() async {
        let viewModel = makeViewModel()

        async let pendingCode = viewModel.requestProveOTP()
        while !viewModel.showProveOTPEntry { await Task.yield() }
        viewModel.submitProveOTP("123456")

        let code = await pendingCode
        XCTAssertEqual(code, "123456")
        XCTAssertFalse(viewModel.showProveOTPEntry,
                       "the sheet closes on submit, before Prove has accepted or rejected the code")
    }

    // MARK: - Confirm

    /// Without a pending verification there is nothing to confirm. The view keys "advance to the
    /// next step" off this return value, so a no-op must report `false` — previously the method
    /// returned Void and the view inferred success from `proveUserInfo`, which this state leaves
    /// untouched and which is therefore indistinguishable from a genuine success.
    func testConfirmWithoutPendingVerificationReportsFailure() async {
        let viewModel = makeViewModel()

        let accepted = await viewModel.confirmTwilioOTP(code: "123456")

        XCTAssertFalse(accepted)
        XCTAssertNil(viewModel.proveUserInfo, "no confirm was attempted, so nothing is verified")
    }

    /// A confirm attempted while another action holds the guard must not advance the flow.
    func testConfirmIsRejectedWhileAnotherActionIsInFlight() async {
        let viewModel = makeViewModel()
        viewModel.pendingTwilioVerificationId = "ver_123"
        viewModel.pendingTwilioVerificationAccountId = "acct_123"
        viewModel.isPerformingAction = true

        let accepted = await viewModel.confirmTwilioOTP(code: "000000")

        XCTAssertFalse(accepted)
        XCTAssertEqual(viewModel.pendingTwilioVerificationId, "ver_123",
                       "a rejected attempt must leave the verification retryable")
        XCTAssertNil(viewModel.proveUserInfo)
    }

    // MARK: - Prove OTP sheet

    /// Dismissing the Prove OTP sheet resumes the suspended `requestProveOTP` continuation with
    /// nil, which the Prove SDK surfaces as an auth error. The cancel must be recorded so the
    /// flow neither toasts nor re-creates behind an applicant who closed the sheet on purpose.
    func testCancellingProveOTPClearsTheSheet() async {
        let viewModel = makeViewModel()

        // Suspend on the OTP sheet the way ProveOtpFinishStep does, then cancel it.
        async let pendingCode = viewModel.requestProveOTP()
        while !viewModel.showProveOTPEntry { await Task.yield() }
        viewModel.cancelProveOTP()

        let code = await pendingCode
        XCTAssertNil(code, "a cancelled sheet supplies no OTP")
        XCTAssertFalse(viewModel.showProveOTPEntry)
    }

    /// Cancelling with no sheet up must not resume a continuation that isn't there, and must not
    /// leave a stale "user cancelled" flag that would swallow a later genuine Prove failure.
    func testCancellingProveOTPWithNoSheetUpIsANoOp() {
        let viewModel = makeViewModel()

        viewModel.cancelProveOTP()

        XCTAssertFalse(viewModel.showProveOTPEntry)
    }
}
