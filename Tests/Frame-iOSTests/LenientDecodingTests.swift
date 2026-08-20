//
//  LenientDecodingTests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/20/26.
//

import XCTest
@testable import Frame

/// Verifies that a malformed optional field degrades to `nil` instead of failing the whole
/// model, while a malformed required field still throws.
final class LenientDecodingTests: XCTestCase {
    private let decoder = JSONDecoder()

    private func capability(_ json: String) throws -> FrameObjects.Capability {
        try decoder.decode(FrameObjects.Capability.self, from: Data(json.utf8))
    }

    // MARK: - Optionals degrade to nil

    func testWrongTypesOnOptionalFieldsDecodeToNil() throws {
        let capability = try self.capability("""
        {
            "id": "cap_123",
            "object": "capability",
            "name": "kyc",
            "account_id": "acc_123",
            "status": "active",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-02T00:00:00Z",
            "disabled_reason": 42,
            "currently_due": "not_an_array",
            "disabled": "not_a_bool"
        }
        """)

        XCTAssertEqual(capability.id, "cap_123")
        XCTAssertEqual(capability.status, "active")
        XCTAssertNil(capability.disabledReason)
        XCTAssertNil(capability.currentlyDue)
        XCTAssertNil(capability.disabled)
    }

    func testMissingOptionalFieldsDecodeToNil() throws {
        let capability = try self.capability("""
        {
            "id": "cap_123",
            "object": "capability",
            "name": "kyc",
            "account_id": "acc_123",
            "status": "active",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-02T00:00:00Z"
        }
        """)

        XCTAssertNil(capability.disabledReason)
        XCTAssertNil(capability.currentlyDue)
        XCTAssertNil(capability.disabled)
    }

    func testExplicitNullDecodesToNil() throws {
        let capability = try self.capability("""
        {
            "id": "cap_123",
            "object": "capability",
            "name": "kyc",
            "account_id": "acc_123",
            "status": "active",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-02T00:00:00Z",
            "disabled_reason": null,
            "disabled": null
        }
        """)

        XCTAssertNil(capability.disabledReason)
        XCTAssertNil(capability.disabled)
    }

    /// One bad element nils the whole array — leniency is per-property, not per-element.
    func testBadElementInsideOptionalArrayNilsEntireArray() throws {
        let capability = try self.capability("""
        {
            "id": "cap_123",
            "object": "capability",
            "name": "kyc",
            "account_id": "acc_123",
            "status": "active",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-02T00:00:00Z",
            "currently_due": ["individual.identity_document", 5]
        }
        """)

        XCTAssertNil(capability.currentlyDue)
    }

    func testValidOptionalFieldsStillDecode() throws {
        let capability = try self.capability("""
        {
            "id": "cap_123",
            "object": "capability",
            "name": "kyc",
            "account_id": "acc_123",
            "status": "inactive",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-02T00:00:00Z",
            "disabled_reason": "requirements_past_due",
            "currently_due": ["individual.identity_document"],
            "disabled": true
        }
        """)

        XCTAssertEqual(capability.disabledReason, "requirements_past_due")
        XCTAssertEqual(capability.currentlyDue, [FrameObjects.CapabilityRequirementKey.identityDocument])
        XCTAssertEqual(capability.disabled, true)
    }

    // MARK: - Required fields still fail

    func testWrongTypeOnRequiredFieldThrows() {
        XCTAssertThrowsError(try capability("""
        {
            "id": 12345,
            "object": "capability",
            "name": "kyc",
            "account_id": "acc_123",
            "status": "active",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-02T00:00:00Z"
        }
        """))
    }

    func testMissingRequiredFieldThrows() {
        XCTAssertThrowsError(try capability("""
        {
            "object": "capability",
            "name": "kyc",
            "account_id": "acc_123",
            "status": "active",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-02T00:00:00Z"
        }
        """))
    }

    // MARK: - Nested models

    /// A bad optional deep inside a nested object must not fail the parent.
    func testBadOptionalInNestedModelDoesNotFailParent() throws {
        let json = """
        {
            "business": null,
            "individual": {
                "name": {
                    "first_name": "Ada",
                    "last_name": "Lovelace",
                    "middle_name": 99,
                    "suffix": ["not", "a", "string"]
                },
                "email": 12345
            }
        }
        """
        let profile = try decoder.decode(FrameObjects.AccountProfile.self, from: Data(json.utf8))

        XCTAssertNil(profile.business)
        XCTAssertEqual(profile.individual?.name?.firstName, "Ada")
        XCTAssertEqual(profile.individual?.name?.lastName, "Lovelace")
        XCTAssertNil(profile.individual?.name?.middleName)
        XCTAssertNil(profile.individual?.name?.suffix)
        XCTAssertNil(profile.individual?.email)
    }

    // MARK: - Encoding round-trip

    /// `@Lenient` must encode exactly as a bare optional does: nil omits the key.
    func testEncodingOmitsNilAndPreservesValues() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let terms = FrameObjects.AccountTermsOfService(token: "tos_123", ipAddress: nil, acceptedAt: "2026-01-01")
        let data = try encoder.encode(terms)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(json.contains("\"token\":\"tos_123\""))
        XCTAssertTrue(json.contains("\"accepted_at\":\"2026-01-01\""))
        XCTAssertFalse(json.contains("ip_address"), "nil must omit the key, not encode null")

        let roundTripped = try JSONDecoder().decode(FrameObjects.AccountTermsOfService.self, from: data)
        XCTAssertEqual(roundTripped, terms)
    }
}

/// `BillingAddress` and `DisputeEvidence` are embedded in outbound request bodies, so
/// `@Lenient` must not alter the JSON the API receives.
final class LenientRequestEncodingTests: XCTestCase {
    func testBillingAddressEncodesIdenticallyToBareOptionals() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let partial = FrameObjects.BillingAddress(city: "Austin", postalCode: "78701")
        let json = String(decoding: try encoder.encode(partial), as: UTF8.self)

        // Only the two populated keys — no nulls for country/state/line_1/line_2.
        XCTAssertEqual(json, #"{"city":"Austin","postal_code":"78701"}"#)
    }

    func testBillingAddressFullyPopulatedEncodesAllKeys() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let full = FrameObjects.BillingAddress(
            city: "Austin", country: "US", state: "TX",
            postalCode: "78701", addressLine1: "1 Main St", addressLine2: "Apt 2"
        )
        let json = String(decoding: try encoder.encode(full), as: UTF8.self)

        XCTAssertEqual(
            json,
            #"{"city":"Austin","country":"US","line_1":"1 Main St","line_2":"Apt 2","postal_code":"78701","state":"TX"}"#
        )
    }
}
