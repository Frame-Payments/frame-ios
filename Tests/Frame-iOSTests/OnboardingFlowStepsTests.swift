import XCTest
@testable import Frame
@testable import FrameOnboarding

final class OnboardingFlowStepsTests: XCTestCase {
    func testIndividualStepsFollowCapabilities() {
        let steps = OnboardingFlow.steps(accountType: .individual,
                                         capabilities: [.kyc, .cardSend, .bankAccountReceive],
                                         showCompletionScreen: true)
        XCTAssertEqual(steps, [.personalInformation, .confirmPaymentMethod, .confirmBankAccount, .verificationSubmitted])
    }

    func testEmptyCapabilitiesStillStartWithPersonalInfo() {
        let steps = OnboardingFlow.steps(accountType: .individual,
                                         capabilities: [],
                                         showCompletionScreen: false)
        XCTAssertEqual(steps, [.personalInformation])
    }

    func testBusinessInsertsDetailsAndOwnersBeforePayment() {
        let steps = OnboardingFlow.steps(accountType: .business,
                                         capabilities: [.kyc, .cardSend, .bankAccountReceive],
                                         showCompletionScreen: true)
        XCTAssertEqual(steps, [
            .personalInformation,
            .businessDetails,
            .ownersAndControllers,
            .confirmPaymentMethod,
            .confirmBankAccount,
            .verificationSubmitted
        ])
    }

    func testBusinessWithoutCapabilitiesStillCollectsTheBusinessSteps() {
        let steps = OnboardingFlow.steps(accountType: .business,
                                         capabilities: [],
                                         showCompletionScreen: false)
        XCTAssertEqual(steps, [.personalInformation, .businessDetails, .ownersAndControllers])
    }
}
