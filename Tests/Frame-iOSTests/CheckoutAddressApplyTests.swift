//
//  CheckoutAddressApplyTests.swift
//  Frame-iOSTests
//

import XCTest
@testable import Frame

@MainActor
final class CheckoutAddressApplyTests: XCTestCase {
    private func makeViewModel() -> FrameCheckoutViewModel {
        FrameCheckoutViewModel(accountId: nil, amount: 100)
    }

    func testApplyFillsEveryAddressField() {
        let viewModel = makeViewModel()

        viewModel.apply(FrameObjects.BillingAddress(
            city: "Austin", country: "US", state: "TX",
            postalCode: "78701", addressLine1: "100 Congress Avenue"
        ))

        XCTAssertEqual(viewModel.customerAddressLine1, "100 Congress Avenue")
        XCTAssertEqual(viewModel.customerCity, "Austin")
        XCTAssertEqual(viewModel.customerState, "TX")
        XCTAssertEqual(viewModel.customerZipCode, "78701")
        XCTAssertEqual(viewModel.customerCountry.alpha2Code, "US")
    }

    /// Mapbox does not reliably return apartment or unit, so whatever the user typed stands.
    func testApplyLeavesAddressLine2Alone() {
        let viewModel = makeViewModel()
        viewModel.customerAddressLine2 = "Apt 4B"

        viewModel.apply(FrameObjects.BillingAddress(
            city: "Austin", country: "US", state: "TX",
            postalCode: "78701", addressLine1: "100 Congress Avenue"
        ))

        XCTAssertEqual(viewModel.customerAddressLine2, "Apt 4B")
    }

    func testApplyClearsErrorsOnTheFilledFields() {
        let viewModel = makeViewModel()
        viewModel.fieldErrors = [
            .addressLine1: "Address is required",
            .city: "City is required",
            .state: "State is required",
            .zip: "Enter a valid ZIP",
            .card: "Card is invalid"
        ]

        viewModel.apply(FrameObjects.BillingAddress(
            city: "Austin", country: "US", state: "TX",
            postalCode: "78701", addressLine1: "100 Congress Avenue"
        ))

        XCTAssertNil(viewModel.fieldErrors[.addressLine1])
        XCTAssertNil(viewModel.fieldErrors[.city])
        XCTAssertNil(viewModel.fieldErrors[.state])
        XCTAssertNil(viewModel.fieldErrors[.zip])
        // Untouched: the card error describes a field this address never wrote.
        XCTAssertEqual(viewModel.fieldErrors[.card], "Card is invalid")
    }

    /// A country the picker does not offer must not move the form off its current one.
    func testApplyIgnoresAnUnknownCountry() {
        let viewModel = makeViewModel()
        let original = viewModel.customerCountry

        viewModel.apply(FrameObjects.BillingAddress(
            city: "Nowhere", country: "ZZ", state: "NA",
            postalCode: "00000", addressLine1: "1 Nowhere Street"
        ))

        XCTAssertEqual(viewModel.customerCountry, original)
    }

    /// A suggestion missing a postal code clears the field rather than leaving a stale one behind.
    func testApplyClearsPostalCodeWhenSuggestionHasNone() {
        let viewModel = makeViewModel()
        viewModel.customerZipCode = "99999"

        viewModel.apply(FrameObjects.BillingAddress(
            city: "Austin", country: "US", state: "TX",
            postalCode: "", addressLine1: "100 Congress Avenue"
        ))

        XCTAssertEqual(viewModel.customerZipCode, "")
    }

    /// An applied address must pass the same validation a typed one does.
    func testAppliedAddressPassesValidation() {
        let viewModel = makeViewModel()

        viewModel.apply(FrameObjects.BillingAddress(
            city: "Austin", country: "US", state: "TX",
            postalCode: "78701", addressLine1: "100 Congress Avenue"
        ))

        XCTAssertNil(Validators.validateNonEmpty(viewModel.customerAddressLine1, fieldName: "Address"))
        XCTAssertNil(Validators.validateNonEmpty(viewModel.customerCity, fieldName: "City"))
        XCTAssertNil(Validators.validateSubregion(viewModel.customerState, countryCode: "US"))
        XCTAssertNil(Validators.validatePostalCode(viewModel.customerZipCode, countryCode: "US"))
    }
}
