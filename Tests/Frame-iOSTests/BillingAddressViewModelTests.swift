//
//  BillingAddressViewModelTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame
@testable import FrameOnboarding

@MainActor
final class BillingAddressViewModelTests: XCTestCase {

    private func makeAddress(country: String,
                             state: String,
                             postal: String) -> FrameObjects.BillingAddress {
        FrameObjects.BillingAddress(city: "Toronto",
                                    country: country,
                                    state: state,
                                    postalCode: postal,
                                    addressLine1: "1 Main St")
    }

    /// Builds a view model with line 1 already marked as selected from a Mapbox suggestion, so
    /// tests exercising other fields aren't tripped up by the selection-required check.
    private func makeViewModel(address: FrameObjects.BillingAddress,
                                mode: BillingAddressMode) -> BillingAddressViewModel {
        let vm = BillingAddressViewModel(address: address, mode: mode)
        vm.isAddressLine1Verified = true
        return vm
    }

    // MARK: - Subregion validation by country

    func testInternational_canadianProvince_isValid() {
        // Regression for FRA-6135: a Canadian address used to be rejected at the address step.
        let vm = makeViewModel(address: makeAddress(country: "CA", state: "ON", postal: "M5V 2T6"),
                                mode: .international)
        XCTAssertTrue(vm.validate())
        XCTAssertNil(vm.errors[.state])
    }

    func testInternational_usStateOnCanadianAddress_isRejected() {
        let vm = makeViewModel(address: makeAddress(country: "CA", state: "TX", postal: "M5V 2T6"),
                                mode: .international)
        XCTAssertFalse(vm.validate())
        XCTAssertNotNil(vm.errors[.state])
    }

    func testInternational_usTerritory_isValid() {
        let vm = makeViewModel(address: makeAddress(country: "US", state: "PR", postal: "00901"),
                                mode: .international)
        XCTAssertTrue(vm.validate())
    }

    func testInternational_unlistedCountry_acceptsFreeTextRegion() {
        let vm = makeViewModel(address: makeAddress(country: "GB", state: "Greater London", postal: "EC1A 1BB"),
                                mode: .international)
        XCTAssertTrue(vm.validate())
    }

    func testInternational_emptyState_isRejectedWithCountryLabel() {
        let vm = makeViewModel(address: makeAddress(country: "CA", state: "", postal: "M5V 2T6"),
                                mode: .international)
        XCTAssertFalse(vm.validate())
        XCTAssertEqual(vm.errors[.state], "Province is required")
    }

    func testUSOnly_forcesUSCountryAndValidatesAgainstUSStates() {
        let vm = makeViewModel(address: makeAddress(country: "CA", state: "ON", postal: "78701"),
                                mode: .usOnly)
        XCTAssertEqual(vm.address.country, "US")
        XCTAssertFalse(vm.validate(), "A Canadian province must not pass in US-only mode")
        XCTAssertNotNil(vm.errors[.state])
    }

    // MARK: - Normalization

    func testNormalize_upcasesValidatedSubregion() {
        let vm = makeViewModel(address: makeAddress(country: "CA", state: " on ", postal: "M5V 2T6"),
                                mode: .international)
        vm.normalize()
        XCTAssertEqual(vm.address.state, "ON")
    }

    func testNormalize_preservesCaseForFreeTextRegion() {
        let vm = makeViewModel(address: makeAddress(country: "FR", state: " Île-de-France ", postal: "75001"),
                                mode: .international)
        vm.normalize()
        XCTAssertEqual(vm.address.state, "Île-de-France")
    }

    func testValidateThenNormalize_lowercaseProvince_roundTrips() {
        let vm = makeViewModel(address: makeAddress(country: "CA", state: "bc", postal: "V6B 1A1"),
                                mode: .international)
        XCTAssertTrue(vm.validate())
        vm.normalize()
        XCTAssertEqual(vm.address.state, "BC")
    }

    // MARK: - Address line 1 selection requirement (FRA-6863)

    func testValidate_unverifiedLine1_isRejected() {
        let vm = BillingAddressViewModel(address: makeAddress(country: "US", state: "TX", postal: "78701"),
                                         mode: .usOnly)
        XCTAssertFalse(vm.validate())
        XCTAssertEqual(vm.errors[.line1], "Select an address from the suggestions")
    }

    func testValidate_verifiedLine1_isAccepted() {
        let vm = makeViewModel(address: makeAddress(country: "US", state: "TX", postal: "78701"),
                                mode: .usOnly)
        XCTAssertTrue(vm.validate())
        XCTAssertNil(vm.errors[.line1])
    }

    func testValidate_emptyLine1_reportsEmptyErrorNotSelectionError() {
        var address = makeAddress(country: "US", state: "TX", postal: "78701")
        address.addressLine1 = ""
        let vm = BillingAddressViewModel(address: address, mode: .usOnly)
        XCTAssertFalse(vm.validate())
        XCTAssertEqual(vm.errors[.line1], "Address line 1 is required")
    }
}
