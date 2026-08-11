//
//  IdentityVerificationCapabilityTests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/9/26.
//

import XCTest
@testable import Frame
@testable import FrameOnboarding

/// Coverage for the `idv` capability, which requires government-ID verification via Persona
/// during onboarding. Its backend requirement (`identity_document`) declares no field keys, so
/// `currently_due` stays empty whether or not verification has happened — `status` is the only
/// signal that it's satisfied. These tests pin both halves of that contract.
final class IdentityVerificationCapabilityTests: XCTestCase {

    func testIdvRawValueMatchesAPIName() {
        XCTAssertEqual(FrameObjects.Capabilities.idv.rawValue, "idv")
        XCTAssertEqual(FrameObjects.Capabilities(rawValue: "idv"), .idv)
    }

    func testIdvRoundTripsThroughCodable() throws {
        let encoded = try JSONEncoder().encode([FrameObjects.Capabilities.idv])
        XCTAssertEqual(String(data: encoded, encoding: .utf8), "[\"idv\"]")

        let decoded = try JSONDecoder().decode([FrameObjects.Capabilities].self, from: encoded)
        XCTAssertEqual(decoded, [.idv])
    }

    /// An account carrying an active `idv` capability is what tells onboarding the applicant
    /// already verified on a previous visit.
    func testAccountDecodesActiveIdvCapability() throws {
        let json = """
        {
          "id": "acc_123",
          "object": "account",
          "type": "individual",
          "status": "active",
          "capabilities": [
            {
              "id": "cap_1",
              "object": "capability",
              "name": "idv",
              "account_id": "acc_123",
              "status": "active",
              "currently_due": [],
              "created": "2026-08-09T00:00:00Z",
              "updated": "2026-08-09T00:00:00Z"
            }
          ],
          "created": 1786000000,
          "updated": 1786000000,
          "livemode": false
        }
        """

        let account = try JSONDecoder().decode(FrameObjects.Account.self, from: Data(json.utf8))
        let idv = account.capabilities?.first { $0.name == FrameObjects.Capabilities.idv.rawValue }

        XCTAssertNotNil(idv)
        XCTAssertEqual(idv?.status, "active")
        // Empty even though verification is complete — hence the reliance on status.
        XCTAssertEqual(idv?.currentlyDue, [])
    }

    /// A pending `idv` looks identical to a satisfied one apart from `status`, which is exactly
    /// why the onboarding completion check can't treat empty `currently_due` as "done" for idv.
    func testPendingIdvIsIndistinguishableByCurrentlyDue() throws {
        let json = """
        {
          "id": "cap_1",
          "object": "capability",
          "name": "idv",
          "account_id": "acc_123",
          "status": "pending",
          "currently_due": [],
          "created": "2026-08-09T00:00:00Z",
          "updated": "2026-08-09T00:00:00Z"
        }
        """

        let capability = try JSONDecoder().decode(FrameObjects.Capability.self, from: Data(json.utf8))
        XCTAssertEqual(capability.status, "pending")
        XCTAssertEqual(capability.currentlyDue, [])
    }

    func testIdvMapsToPersonalInformationStep() {
        XCTAssertEqual(FrameObjects.Capabilities.idv.onboardingStep, .personalInformation)
    }

    // MARK: - Capability completion

    private func capability(name: String, status: String, currentlyDue: [String]?) -> FrameObjects.Capability {
        FrameObjects.Capability(
            id: "cap_\(name)",
            object: "capability",
            name: name,
            accountId: "acc_123",
            status: status,
            disabledReason: nil,
            currentlyDue: currentlyDue,
            created: "2026-08-09T00:00:00Z",
            updated: "2026-08-09T00:00:00Z",
            disabled: nil
        )
    }

    /// Regression guard: `idv` reports an empty `currently_due` even while verification is still
    /// outstanding. Dropping it on that basis alone would skip verification entirely for any
    /// returning account.
    @MainActor
    func testPendingIdvIsRetainedDespiteEmptyCurrentlyDue() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.idv, .kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "idv", status: "pending", currentlyDue: [])
        ])

        XCTAssertTrue(viewModel.requiredCapabilities.contains(.idv))
    }

    @MainActor
    func testActiveIdvIsDropped() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.idv, .kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "idv", status: "active", currentlyDue: [])
        ])

        XCTAssertFalse(viewModel.requiredCapabilities.contains(.idv))
    }

    /// The status condition is scoped to `idv` — every other capability still completes purely on
    /// an empty `currently_due`, regardless of status.
    @MainActor
    func testNonIdvCapabilityStillDropsOnEmptyCurrentlyDueWhilePending() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "kyc", status: "pending", currentlyDue: [])
        ])

        XCTAssertFalse(viewModel.requiredCapabilities.contains(.kyc))
    }

    /// `profile` is withheld unless the request carries a secret key or a matching onboarding
    /// session, so the already-verified seeding must not sit behind the profile guard — an account
    /// payload with capabilities but no profile still has to reveal an active idv.
    func testAccountWithoutProfileStillExposesCapabilities() throws {
        let json = """
        {
          "id": "acc_123",
          "object": "account",
          "type": "individual",
          "status": "active",
          "capabilities": [
            {
              "id": "cap_1",
              "object": "capability",
              "name": "idv",
              "account_id": "acc_123",
              "status": "active",
              "currently_due": [],
              "created": "2026-08-09T00:00:00Z",
              "updated": "2026-08-09T00:00:00Z"
            }
          ],
          "created": 1786000000,
          "updated": 1786000000,
          "livemode": false
        }
        """

        let account = try JSONDecoder().decode(FrameObjects.Account.self, from: Data(json.utf8))
        XCTAssertNil(account.profile)
        XCTAssertTrue(account.capabilities?.contains { $0.name == "idv" && $0.status == "active" } == true)
    }

    /// A capability with outstanding fields stays required whatever its status.
    @MainActor
    func testCapabilityWithOutstandingFieldsIsRetained() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "kyc", status: "pending", currentlyDue: ["individual.ssn_last_four"])
        ])

        XCTAssertTrue(viewModel.requiredCapabilities.contains(.kyc))
    }

    // MARK: - Step-up via currently_due

    /// Step-up arrives as a `currently_due` key on an existing capability, with no `idv` capability
    /// provisioned. Missing it lets the applicant through unverified.
    @MainActor
    func testIdentityDocumentDueOnKycRequiresGovernmentId() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "kyc", status: "pending", currentlyDue: ["individual.identity_document"])
        ])

        XCTAssertTrue(viewModel.identityDocumentRequired)
        XCTAssertTrue(viewModel.governmentIdRequired)
    }

    /// The scan can't be scoped to kyc.
    @MainActor
    func testIdentityDocumentDueOnBankAccountReceiveRequiresGovernmentId() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.bankAccountReceive])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "bank_account_receive",
                       status: "pending",
                       currentlyDue: ["individual.identity_document", "payout.method_type"])
        ])

        XCTAssertTrue(viewModel.identityDocumentRequired)
        XCTAssertTrue(viewModel.governmentIdRequired)
    }

    /// `idv` remains an independent trigger, needing no `currently_due` key.
    @MainActor
    func testIdvCapabilityAloneRequiresGovernmentId() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.idv])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "idv", status: "pending", currentlyDue: [])
        ])

        XCTAssertFalse(viewModel.identityDocumentRequired)
        XCTAssertTrue(viewModel.governmentIdRequired)
    }

    @MainActor
    func testNoIdentityDocumentAndNoIdvDoesNotRequireGovernmentId() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "kyc", status: "pending", currentlyDue: ["individual.ssn_last_four"])
        ])

        XCTAssertFalse(viewModel.identityDocumentRequired)
        XCTAssertFalse(viewModel.governmentIdRequired)
    }

    /// The flag tracks the latest payload rather than latching on.
    @MainActor
    func testIdentityDocumentRequirementClearsWhenNoLongerDue() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "kyc", status: "pending", currentlyDue: ["individual.identity_document"])
        ])
        XCTAssertTrue(viewModel.identityDocumentRequired)

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "kyc", status: "active", currentlyDue: [])
        ])
        XCTAssertFalse(viewModel.identityDocumentRequired)
    }

    /// "Use SSN instead" must not erase a backend-declared requirement, or the submit guard would
    /// wave the applicant through.
    @MainActor
    func testResetKeepsIdentityDocumentRequirement() {
        let viewModel = OnboardingContainerViewModel(accountId: "acc_123", requiredCapabilities: [.kyc])

        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: [
            capability(name: "kyc", status: "pending", currentlyDue: ["individual.identity_document"])
        ])
        viewModel.identityVerifiedViaGovId = true

        viewModel.resetIdentityVerification()

        XCTAssertFalse(viewModel.identityVerifiedViaGovId)
        XCTAssertTrue(viewModel.governmentIdRequired)
    }

    // MARK: - SSN validation

    private func identity(ssn: String) -> CustomerIdentityRequest.CreateCustomerIdentityRequest {
        CustomerIdentityRequest.CreateCustomerIdentityRequest(
            firstName: "Ada", lastName: "Lovelace", dateOfBirth: "1990-01-01",
            email: "ada@example.com", phoneNumber: "+12125550123",
            ssn: ssn, address: FrameObjects.BillingAddress(postalCode: "10001")
        )
    }

    /// With verification pending, the SSN row is hidden — so validation must not demand one, or
    /// Continue is dead with no visible field to fix.
    @MainActor
    func testSkipSSNAllowsEmptySSN() {
        let viewModel = CustomerInformationViewModel(identity: identity(ssn: ""))
        viewModel.skipSSN = true

        XCTAssertTrue(viewModel.validate())
        XCTAssertNil(viewModel.errors[.ssn])
    }

    @MainActor
    func testSSNStillValidatedWhenNotSkipped() {
        let viewModel = CustomerInformationViewModel(identity: identity(ssn: ""))

        XCTAssertFalse(viewModel.validate())
        XCTAssertNotNil(viewModel.errors[.ssn])
    }

    /// A typo here silently disables step-up.
    func testIdentityDocumentRequirementKeyMatchesAPI() {
        XCTAssertEqual(FrameObjects.CapabilityRequirementKey.identityDocument, "individual.identity_document")
    }

    /// The real payload from a stepped-up sandbox account.
    @MainActor
    func testRealStepUpPayloadRequiresGovernmentId() throws {
        let json = """
        [
          {"id":"c1","object":"capability","name":"kyc_prefill","account_id":"acc_1","status":"active",
           "currently_due":[],"created":"2026-08-11T17:04:08Z","updated":"2026-08-11T17:06:17Z"},
          {"id":"c2","object":"capability","name":"card_send","account_id":"acc_1","status":"pending",
           "currently_due":["source.method_type","source.card.number"],
           "created":"2026-08-11T17:04:08Z","updated":"2026-08-11T17:04:08Z"},
          {"id":"c3","object":"capability","name":"geo_compliance","account_id":"acc_1","status":"active",
           "currently_due":[],"created":"2026-08-11T17:04:09Z","updated":"2026-08-11T17:04:09Z"},
          {"id":"c4","object":"capability","name":"bank_account_receive","account_id":"acc_1","status":"pending",
           "currently_due":["individual.identity_document","payout.method_type"],
           "created":"2026-08-11T17:04:09Z","updated":"2026-08-11T17:04:09Z"},
          {"id":"c5","object":"capability","name":"age_verification","account_id":"acc_1","status":"active",
           "currently_due":[],"created":"2026-08-11T17:04:09Z","updated":"2026-08-11T17:04:32Z"},
          {"id":"c6","object":"capability","name":"kyc","account_id":"acc_1","status":"pending",
           "currently_due":["individual.identity_document"],
           "created":"2026-08-11T17:04:09Z","updated":"2026-08-11T17:04:09Z"},
          {"id":"c7","object":"capability","name":"phone_verification","account_id":"acc_1","status":"active",
           "currently_due":[],"created":"2026-08-11T17:04:09Z","updated":"2026-08-11T17:04:32Z"}
        ]
        """

        let capabilities = try JSONDecoder().decode([FrameObjects.Capability].self, from: Data(json.utf8))
        XCTAssertFalse(capabilities.contains { $0.name == "idv" })

        let viewModel = OnboardingContainerViewModel(accountId: "acc_1", requiredCapabilities: [.kyc, .bankAccountReceive])
        viewModel.updateCapabilitiesBasedOnCompletion(accountCapabilities: capabilities)

        XCTAssertTrue(viewModel.governmentIdRequired)
        XCTAssertTrue(viewModel.requiredCapabilities.contains(.kyc))
    }
}
