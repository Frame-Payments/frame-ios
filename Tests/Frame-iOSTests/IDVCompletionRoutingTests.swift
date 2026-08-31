//
//  IDVCompletionRoutingTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame
@testable import FrameOnboarding

/// Coverage for what an applicant is told when `/idv/complete` doesn't come back verified. Every
/// outcome used to share one "try again" toast, which sends a declined applicant round a dead loop.
final class IDVCompletionRoutingTests: XCTestCase {

    private func decodeCompletion(_ payload: [String: Any]) throws -> IDVCompleteResponse {
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(IDVCompleteResponse.self, from: data)
    }

    // MARK: - Decoding the shipped contract

    func testDecodesRemediationFields() throws {
        let completion = try decodeCompletion([
            "verified": false,
            "status": "declined",
            "failure_type": "verification_rejected",
            "category": "terminal",
            "retriable": false
        ])

        XCTAssertEqual(completion.verified, false)
        XCTAssertEqual(completion.status, "declined")
        XCTAssertEqual(completion.failureType, "verification_rejected")
        XCTAssertEqual(completion.category, "terminal")
        XCTAssertEqual(completion.retriable, false)
    }

    /// Null until the KYC run concludes, and null once a document answered its step-up.
    func testDecodesNullRemediationFields() throws {
        let completion = try decodeCompletion([
            "verified": true,
            "status": "needs_review",
            "failure_type": NSNull(),
            "category": NSNull(),
            "retriable": NSNull()
        ])

        XCTAssertEqual(completion.verified, true)
        XCTAssertEqual(completion.status, "needs_review")
        XCTAssertNil(completion.failureType)
        XCTAssertNil(completion.category)
        XCTAssertNil(completion.retriable)
    }

    /// A response missing `verified` must never read as verified.
    func testMissingVerifiedDecodesToNilNotTrue() throws {
        let completion = try decodeCompletion(["status": "pending"])
        XCTAssertNil(completion.verified)
        XCTAssertNotEqual(completion.verified, true)
    }

    // MARK: - Message routing

    /// A terminal decline must not invite a retry.
    func testTerminalCategoryPointsToSupportNotRetry() {
        let completion = IDVCompleteResponse(verified: false, status: "declined",
                                             failureType: "verification_rejected",
                                             category: "terminal", retriable: false)
        let message = OnboardingContainerViewModel.idvFailureMessage(for: completion)
        XCTAssertTrue(message.contains("contact support"))
        XCTAssertFalse(message.lowercased().contains("try again"))
    }

    func testReviewCategorySaysReviewNotFailure() {
        let completion = IDVCompleteResponse(verified: false, status: "needs_review",
                                             failureType: "review_pending",
                                             category: "review", retriable: false)
        XCTAssertTrue(OnboardingContainerViewModel.idvFailureMessage(for: completion).contains("in review"))
    }

    func testRetriableCategoryAsksForCorrectedDetails() {
        let completion = IDVCompleteResponse(verified: false, status: "failed",
                                             failureType: "identity_mismatch",
                                             category: "retriable_with_new_data", retriable: true)
        XCTAssertTrue(OnboardingContainerViewModel.idvFailureMessage(for: completion).contains("didn't match"))
    }

    func testStepUpCategoryAsksForGovernmentId() {
        let completion = IDVCompleteResponse(verified: false, status: "pending",
                                             failureType: "identity_not_found",
                                             category: "step_up", retriable: false)
        let message = OnboardingContainerViewModel.idvFailureMessage(for: completion)
        XCTAssertTrue(message.contains("government ID"))
        XCTAssertFalse(message.contains("contact support"))
    }

    /// When the KYC run has no conclusion, the document's own status is the documented fallback.
    func testFallsBackToDocumentStatusWhenCategoryIsNil() {
        let declined = IDVCompleteResponse(verified: false, status: "declined")
        XCTAssertTrue(OnboardingContainerViewModel.idvFailureMessage(for: declined).contains("contact support"))

        let failed = IDVCompleteResponse(verified: false, status: "failed")
        XCTAssertTrue(OnboardingContainerViewModel.idvFailureMessage(for: failed).contains("contact support"))

        let review = IDVCompleteResponse(verified: false, status: "needs_review")
        XCTAssertTrue(OnboardingContainerViewModel.idvFailureMessage(for: review).contains("in review"))
    }

    /// Nothing concluded yet: keep the original retry-or-SSN copy.
    func testUnknownStateKeepsRetryGuidance() {
        let completion = IDVCompleteResponse(verified: false, status: "pending")
        XCTAssertTrue(OnboardingContainerViewModel.idvFailureMessage(for: completion).contains("Social Security Number"))

        XCTAssertTrue(OnboardingContainerViewModel.idvFailureMessage(for: nil).contains("Social Security Number"))
    }
}
