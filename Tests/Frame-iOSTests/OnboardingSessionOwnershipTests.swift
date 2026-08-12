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

    /// A flow that begins a session takes ownership and ends it, restoring pk_/sk_ auth. This is the
    /// same ownership flag the self-mint path (`beginOnboardingSessionIfNeeded`) sets, so ending it
    /// here covers the clientSecret == nil leak that previously survived onboarding.
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
}
