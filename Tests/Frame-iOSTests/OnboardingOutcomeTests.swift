//
//  OnboardingOutcomeTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame
@testable import FrameOnboarding

/// Coverage for how onboarding decides whether it actually succeeded: which capabilities count as
/// outstanding, and which ending they produce.
final class OnboardingOutcomeTests: XCTestCase {

    private func capability(name: String,
                            status: String,
                            disabledReason: String? = nil,
                            currentlyDue: [String]? = [],
                            errors: [FrameObjects.CapabilityError]? = nil) throws -> FrameObjects.Capability {
        var payload: [String: Any] = [
            "id": "cap_1",
            "object": "capability",
            "name": name,
            "account_id": "acc_123",
            "status": status,
            "created": "2026-08-28T00:00:00Z",
            "updated": "2026-08-28T00:00:00Z"
        ]
        if let disabledReason { payload["disabled_reason"] = disabledReason }
        if let currentlyDue { payload["currently_due"] = currentlyDue }
        if let errors {
            payload["errors"] = errors.map { error in
                [
                    "id": error.id,
                    "object": "capability_error",
                    "code": error.code as Any,
                    "message": error.message as Any
                ]
            }
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(FrameObjects.Capability.self, from: data)
    }

    private func error(code: String, message: String? = nil) -> FrameObjects.CapabilityError {
        let payload: [String: Any] = [
            "id": "cerr_1",
            "object": "capability_error",
            "code": code,
            "message": message ?? "Something went wrong."
        ]
        // Decoded so the test exercises the same path the API does.
        let data = try! JSONSerialization.data(withJSONObject: payload)
        return try! JSONDecoder().decode(FrameObjects.CapabilityError.self, from: data)
    }

    // MARK: - isOutstanding mirrors the server's blocks_activation?

    func testActiveCapabilityIsNotOutstanding() throws {
        let capability = try capability(name: "kyc", status: "active")
        XCTAssertFalse(capability.isOutstanding)
    }

    func testPendingCapabilityIsOutstanding() throws {
        let capability = try capability(name: "kyc", status: "pending")
        XCTAssertTrue(capability.isOutstanding)
    }

    /// The applicant cannot act on it, so it never blocks.
    func testIneligibleCapabilityIsNotOutstanding() throws {
        let capability = try capability(name: "kyc", status: "ineligible")
        XCTAssertFalse(capability.isOutstanding)
    }

    /// A request that never landed was never held.
    func testUnrequestedCapabilityIsNotOutstanding() throws {
        let capability = try capability(name: "kyc", status: "unrequested")
        XCTAssertFalse(capability.isOutstanding)
    }

    func testRiskDisabledCapabilityIsOutstanding() throws {
        let capability = try capability(name: "kyc", status: "disabled", disabledReason: "kyc_failed")
        XCTAssertTrue(capability.isOutstanding)
    }

    /// A revoked product grant is a commercial change, not a verdict about the applicant.
    func testCommercialDisableIsNotOutstanding() throws {
        let capability = try capability(name: "kyc",
                                        status: "disabled",
                                        disabledReason: "product_grant_revoked")
        XCTAssertFalse(capability.isOutstanding)
    }

    /// A status this SDK version doesn't know is not evidence of success.
    func testUnknownStatusIsOutstandingAndDecodes() throws {
        let capability = try capability(name: "kyc", status: "some_future_state")
        XCTAssertEqual(capability.capabilityStatus, .unknown)
        XCTAssertTrue(capability.isOutstanding)
    }

    /// `GET /v1/accounts/{id}` passes no `due_keys`, so `currently_due` serializes empty there for
    /// every capability — status is the only usable signal on the fetch the flow actually makes.
    func testEmptyCurrentlyDueDoesNotImplySatisfied() throws {
        XCTAssertTrue(try capability(name: "idv", status: "pending", currentlyDue: []).isOutstanding)
        XCTAssertTrue(try capability(name: "kyc", status: "pending", currentlyDue: []).isOutstanding)
    }

    // MARK: - Outcome resolution

    func testAllRequiredCapabilitiesActiveIsApproved() throws {
        let capabilities = [
            try capability(name: "kyc", status: "active"),
            try capability(name: "idv", status: "active")
        ]
        let outcome = OnboardingOutcome.resolve(from: capabilities, required: [.kyc, .idv])
        XCTAssertEqual(outcome, .approved)
        XCTAssertTrue(outcome.isSuccess)
    }

    /// A capability the merchant never asked about must not fail an otherwise complete onboarding.
    func testUnrequiredOutstandingCapabilityIsIgnored() throws {
        let capabilities = [
            try capability(name: "kyc", status: "active"),
            try capability(name: "bank_account_verification", status: "pending")
        ]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]), .approved)
    }

    /// Outstanding with no conclusion yet is a wait, not a failure.
    func testPendingWithNoErrorsIsPendingReview() throws {
        let capabilities = [try capability(name: "kyc", status: "pending")]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]), .pendingReview)
    }

    func testVerificationRejectedIsDeclined() throws {
        let capabilities = [
            try capability(name: "kyc",
                           status: "disabled",
                           disabledReason: "kyc_failed",
                           errors: [error(code: "verification_rejected",
                                          message: "Identity verification was rejected.")])
        ]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]),
                       .declined(message: "Identity verification was rejected."))
    }

    /// `step_up` reports `retriable: false` but is not a decline — documents are still the path.
    func testIdentityNotFoundIsActionRequiredNotDeclined() throws {
        let capabilities = [
            try capability(name: "kyc",
                           status: "pending",
                           errors: [error(code: "identity_not_found",
                                          message: "No sufficient identity record was found.")])
        ]
        let outcome = OnboardingOutcome.resolve(from: capabilities, required: [.kyc])
        XCTAssertEqual(outcome, .actionRequired(message: "No sufficient identity record was found."))
        if case .declined = outcome { XCTFail("step_up must never resolve to a decline") }
    }

    func testIdentityMismatchIsActionRequired() throws {
        let capabilities = [
            try capability(name: "kyc",
                           status: "pending",
                           errors: [error(code: "identity_mismatch", message: "Details didn't match.")])
        ]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]),
                       .actionRequired(message: "Details didn't match."))
    }

    /// A run under review has reached no conclusion, so it must not read as a failure.
    func testReviewPendingStaysPendingReview() throws {
        let capabilities = [
            try capability(name: "kyc",
                           status: "pending",
                           errors: [error(code: "review_pending", message: "In manual review.")])
        ]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]), .pendingReview)
    }

    /// A decline must not hide behind a milder conclusion on another capability.
    func testDeclineOutranksOtherOutstandingCapabilities() throws {
        let capabilities = [
            try capability(name: "idv", status: "pending"),
            try capability(name: "kyc",
                           status: "disabled",
                           disabledReason: "kyc_failed",
                           errors: [error(code: "verification_rejected", message: "Rejected.")])
        ]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc, .idv]),
                       .declined(message: "Rejected."))
    }

    /// Resolving against a drained set would fall into this branch and judge onboarding on
    /// capabilities the merchant never asked about.
    func testEmptyRequiredFallsBackToAllCapabilities() throws {
        let capabilities = [try capability(name: "kyc", status: "pending")]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: []), .pendingReview)
    }

    /// The view model must resolve against the launch-time set, not the drained one.
    @MainActor
    func testViewModelRetainsOriginalRequiredCapabilities() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123",
                                                     requiredCapabilities: [.kyc, .idv])
        viewModel.requiredCapabilities.removeAll()
        XCTAssertEqual(viewModel.originallyRequiredCapabilities, [.kyc, .idv])
    }

    /// `transient` is a wait, not something the applicant can act on — the backend classifies
    /// provider_error and signals_unavailable that way.
    func testTransientCodesStayPendingReview() throws {
        for code in ["provider_error", "signals_unavailable"] {
            let capabilities = [
                try capability(name: "kyc", status: "pending", errors: [error(code: code)])
            ]
            XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]),
                           .pendingReview, "\(code) must not demand action")
        }
    }

    /// A failure type added server-side must not read as a demand for action.
    func testUnrecognizedCodeStaysPendingReview() throws {
        let capabilities = [
            try capability(name: "kyc", status: "pending", errors: [error(code: "some_new_type")])
        ]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]), .pendingReview)
    }

    func testUnclassifiedStaysPendingReview() throws {
        let capabilities = [
            try capability(name: "kyc", status: "pending", errors: [error(code: "unclassified")])
        ]
        XCTAssertEqual(OnboardingOutcome.resolve(from: capabilities, required: [.kyc]), .pendingReview)
    }

    /// Only an approval reports success to the host.
    func testOnlyApprovedIsSuccess() {
        XCTAssertTrue(OnboardingOutcome.approved.isSuccess)
        XCTAssertFalse(OnboardingOutcome.pendingReview.isSuccess)
        XCTAssertFalse(OnboardingOutcome.declined(message: nil).isSuccess)
        XCTAssertFalse(OnboardingOutcome.actionRequired(message: nil).isSuccess)
    }
}
