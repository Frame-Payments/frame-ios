//
//  OnboardingSessionOwnershipTests.swift
//  Frame-iOS
//
//  Guards that an onboarding flow ends the onboarding session it owns — including a session the
//  flow self-mints when the host supplies no client secret — so a stale onb_sess_ token doesn't
//  leak past onboarding into a later checkout.
//

import XCTest
@testable import Frame
@testable import FrameOnboarding

@MainActor
final class OnboardingSessionOwnershipTests: XCTestCase {

    override func tearDown() {
        // Shared singleton: clear any session so ownership state doesn't bleed into other tests.
        FrameNetworking.shared.endOnboardingSession()
        super.tearDown()
    }

    private func makeViewModel() -> OnboardingContainerViewModel {
        FrameNetworking.shared.endOnboardingSession() // clean auth context per test
        return OnboardingContainerViewModel(accountId: "acct_123", requiredCapabilities: [])
    }

    /// A flow that begins a host-supplied session takes ownership and ends it, restoring pk_/sk_ auth.
    func testOwnedSessionIsEnded() {
        let viewModel = makeViewModel()

        viewModel.beginOnboardingSession(clientSecret: "onb_sess_live_token")
        XCTAssertTrue(viewModel.ownsOnboardingSession)
        XCTAssertTrue(FrameNetworking.shared.hasActiveOnboardingSession)

        viewModel.endOnboardingSessionIfOwned()
        XCTAssertFalse(viewModel.ownsOnboardingSession)
        XCTAssertFalse(FrameNetworking.shared.hasActiveOnboardingSession)
    }

    /// A flow that never began a session must not wipe one another flow started — ownership gates
    /// the teardown.
    func testUnownedSessionIsNotEnded() {
        let viewModel = makeViewModel()

        // Simulate a session begun elsewhere, not by this flow.
        FrameNetworking.shared.beginOnboardingSession(clientSecret: "onb_sess_other_flow")
        XCTAssertFalse(viewModel.ownsOnboardingSession)

        viewModel.endOnboardingSessionIfOwned()
        XCTAssertTrue(FrameNetworking.shared.hasActiveOnboardingSession,
                      "a session this flow doesn't own should be left intact")
    }

    // MARK: - Standalone add/select-method screens (FRA-6358)

    /// The host mints the session. Loading an account does not create one with the publishable key.
    func testLoadingAnAccountDoesNotMintASession() async throws {
        let savedSession = FrameNetworking.shared.asyncURLSession
        defer { FrameNetworking.shared.asyncURLSession = savedSession }

        let mock = MockURLAsyncSession(
            data: Data(#"{ "id": "onb_1", "client_secret": "onb_sess_self_minted" }"#.utf8),
            response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/onboarding_sessions")!,
                                      statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )
        FrameNetworking.shared.asyncURLSession = mock

        let viewModel = makeViewModel()
        await viewModel.checkExistingAccount()

        XCTAssertFalse(FrameNetworking.shared.hasActiveOnboardingSession)
        XCTAssertFalse(viewModel.ownsOnboardingSession)
    }

    /// Teardown must not depend on `isPerformingAction` having settled — the success callback can
    /// run while `beginAction()` is in flight, the state that made `.onDisappear` return early.
    func testTeardownWorksWhileAnActionIsInFlight() {
        let viewModel = makeViewModel()
        viewModel.beginOnboardingSession(clientSecret: "onb_sess_live_token")

        // beginAction() is private; this is the state it sets and the state the old .onDisappear
        // guard tripped over.
        viewModel.isPerformingAction = true

        viewModel.endOnboardingSessionIfOwned()

        XCTAssertFalse(FrameNetworking.shared.hasActiveOnboardingSession)
    }

    /// Dismissing the screen before the account read returns must not install a session. The SDK
    /// does not mint one.
    func testMintCompletingAfterTeardownDoesNotInstallASession() async throws {
        let savedSession = FrameNetworking.shared.asyncURLSession
        defer { FrameNetworking.shared.asyncURLSession = savedSession }

        let mock = MockURLAsyncSession(
            data: Data(#"{ "id": "onb_1", "client_secret": "onb_sess_late_mint" }"#.utf8),
            response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/onboarding_sessions")!,
                                      statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )
        FrameNetworking.shared.asyncURLSession = mock

        let viewModel = makeViewModel()

        // The screen resolved (host dismissed) before the in-flight mint came back.
        viewModel.endOnboardingSessionIfOwned()
        await viewModel.checkExistingAccount()

        XCTAssertFalse(FrameNetworking.shared.hasActiveOnboardingSession,
                       "a mint that lands after teardown has nothing left to end it and would leak")
        XCTAssertFalse(viewModel.ownsOnboardingSession)
    }

    /// Ending twice is a no-op, so the success callback's teardown followed by `.onDisappear`'s
    /// can't wipe a session a later flow began in between.
    func testDoubleTeardownIsIdempotent() {
        let viewModel = makeViewModel()
        viewModel.beginOnboardingSession(clientSecret: "onb_sess_live_token")
        viewModel.endOnboardingSessionIfOwned()

        // A different flow starts its own session after this screen resolved.
        FrameNetworking.shared.beginOnboardingSession(clientSecret: "onb_sess_next_flow")
        viewModel.endOnboardingSessionIfOwned()

        XCTAssertTrue(FrameNetworking.shared.hasActiveOnboardingSession,
                      "the second teardown must not clear a session this flow no longer owns")
    }
}
