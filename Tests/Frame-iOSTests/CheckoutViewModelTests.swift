//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/21/24.
//

import XCTest
import EvervaultInputs
@testable import Frame

final class CheckoutViewModelTests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/payment_methods")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)

    @MainActor func testLoadCustomerPaymentMethods() async {
        FrameNetworking.shared.asyncURLSession = session

        // Test with invalid customer ID
        let viewModel = FrameCheckoutViewModel(customerId: "", amount: 100)
        await viewModel.loadCustomerPaymentMethods()
        XCTAssertNil(viewModel.customerPaymentOptions)

        // Test with valid customer ID with no payment methods
        let viewModelTwo = FrameCheckoutViewModel(customerId: "1", amount: 100)
        await viewModelTwo.loadCustomerPaymentMethods()
        XCTAssertNil(viewModelTwo.customerPaymentOptions)

        // Test with valid customer ID with payment method
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let customer = FrameObjects.Customer(id: "1", livemode: false, name: "Tester", paymentMethods: [paymentMethod])

        session.data = try? JSONEncoder().encode(customer)
        let viewModelThree = FrameCheckoutViewModel(customerId: "1", amount: 100)
        await viewModelThree.loadCustomerPaymentMethods()
        XCTAssertNotNil(viewModelThree.customerPaymentOptions)
        XCTAssertEqual(viewModelThree.customerPaymentOptions?.first?.id, "1")
    }

    // MARK: Helpers

    private func validCardData() -> PaymentCardData {
        var data = PaymentCardData()
        data.card.number = "4242424242424242"
        data.card.expMonth = "12"
        data.card.expYear = "2030"
        data.card.cvc = "123"
        data.card.lastFour = "4242"
        return data
    }

    @MainActor private func fillValidCustomerInfo(_ vm: FrameCheckoutViewModel) {
        vm.customerName = "Tester McTest"
        vm.customerEmail = "tester@example.com"
        vm.cardData = validCardData()
    }

    @MainActor private func fillValidAddress(_ vm: FrameCheckoutViewModel) {
        vm.customerAddressLine1 = "123 Main St"
        vm.customerCity = "Burbank"
        vm.customerState = "California"
        vm.customerCountry = AvailableCountry.defaultCountry
        vm.customerZipCode = "75115"
    }

    @MainActor func testCreatePaymentMethod() async {
        FrameNetworking.shared.asyncURLSession = session

        let paymentCardData = validCardData()
        let paymentCard = FrameObjects.PaymentCard(brand: paymentCardData.card.type?.brand ?? "",
                                                   expirationMonth: paymentCardData.card.expMonth,
                                                   expirationYear: paymentCardData.card.expYear,
                                                   currency: "USD",
                                                   lastFourDigits: paymentCardData.card.lastFour)

        // Test with no customer country or customer Zip Code
        session.data = try? JSONEncoder().encode(FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard, status: .active))
        let viewModel = FrameCheckoutViewModel(customerId: "", amount: 100)
        viewModel.customerName = "Tester McTest"
        viewModel.customerEmail = "tester@example.com"
        viewModel.customerZipCode = ""
        let firstMethod = try? await viewModel.createPaymentMethod()
        XCTAssertNil(firstMethod?.paymentId)
        XCTAssertNil(firstMethod?.customerId)

        viewModel.customerCountry = AvailableCountry.defaultCountry
        viewModel.customerZipCode = "75115"
        viewModel.cardData = PaymentCardData()

        // Test with invalid/null card data
        session.data = nil
        let secondMethod = try? await viewModel.createPaymentMethod()
        XCTAssertNil(secondMethod?.paymentId)
        XCTAssertNil(secondMethod?.customerId)

        viewModel.cardData = paymentCardData
        viewModel.customerZipCode = ""

        // Test invalid zipCode and valid card data
        session.data = try? JSONEncoder().encode(FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard, status: .active))
        let thirdMethod = try? await viewModel.createPaymentMethod()
        XCTAssertNil(thirdMethod?.paymentId)
        XCTAssertNil(thirdMethod?.customerId)

        fillValidAddress(viewModel)

        let billingAddress = FrameObjects.BillingAddress(country: viewModel.customerCountry.displayName, postalCode: viewModel.customerZipCode)
        let method = FrameObjects.PaymentMethod(id: "1", billing: billingAddress, type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard, status: .active)

        // Test with valid zipCode and valid card data
        session.data = try? JSONEncoder().encode(method)
        let fourthMethod = try? await viewModel.createPaymentMethod(customerId: "111")
        XCTAssertNotNil(fourthMethod)
        XCTAssertEqual(fourthMethod?.customerId, "111")
    }

    // MARK: Validators (pure)

    func testValidateNonEmpty() {
        XCTAssertNil(Validators.validateNonEmpty("hello", fieldName: "Name"))
        XCTAssertNotNil(Validators.validateNonEmpty("", fieldName: "Name"))
        XCTAssertNotNil(Validators.validateNonEmpty("   ", fieldName: "Name"))
    }

    func testValidateFullName() {
        XCTAssertNil(Validators.validateFullName("Tester McTest"))
        XCTAssertNil(Validators.validateFullName("Mary Jane Watson"))
        XCTAssertNil(Validators.validateFullName("  Tester   McTest  "))
        XCTAssertNotNil(Validators.validateFullName(""))
        XCTAssertNotNil(Validators.validateFullName("   "))
        XCTAssertNotNil(Validators.validateFullName("Tester"))
        XCTAssertNotNil(Validators.validateFullName("Tester  "))
    }

    func testValidateEmail() {
        XCTAssertNil(Validators.validateEmail("user@example.com"))
        XCTAssertNil(Validators.validateEmail("a.b+c@d.co"))
        XCTAssertNotNil(Validators.validateEmail(""))
        XCTAssertNotNil(Validators.validateEmail("foo@"))
        XCTAssertNotNil(Validators.validateEmail("foo.bar"))
        XCTAssertNotNil(Validators.validateEmail("foo @bar.com"))
    }

    func testValidateZipUS() {
        XCTAssertNil(Validators.validateZipUS("75115"))
        XCTAssertNotNil(Validators.validateZipUS(""))
        XCTAssertNotNil(Validators.validateZipUS("1234"))
        XCTAssertNotNil(Validators.validateZipUS("123456"))
        XCTAssertNotNil(Validators.validateZipUS("abcde"))
    }

    // MARK: validateAll branching by addressMode

    @MainActor func testRequired_blankAddress_populatesErrors() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.addressLine1])
        XCTAssertNotNil(vm.fieldErrors[.city])
        XCTAssertNotNil(vm.fieldErrors[.state])
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }

    @MainActor func testOptional_allBlank_isValid() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .optional)
        fillValidCustomerInfo(vm)
        XCTAssertTrue(vm.validateAll(forSavedCard: false))
        XCTAssertNil(vm.fieldErrors[.addressLine1])
        XCTAssertNil(vm.fieldErrors[.zip])
    }

    @MainActor func testOptional_partialAddress_failsValidation() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .optional)
        fillValidCustomerInfo(vm)
        vm.customerCity = "Burbank" // partial fill triggers all-or-nothing
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.addressLine1])
        XCTAssertNotNil(vm.fieldErrors[.state])
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }

    @MainActor func testHidden_neverValidatesAddress() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        fillValidCustomerInfo(vm)
        // Even with garbage in address fields, hidden mode skips validation entirely.
        vm.customerCity = "x"
        vm.customerZipCode = "1"
        XCTAssertTrue(vm.validateAll(forSavedCard: false))
        XCTAssertNil(vm.fieldErrors[.zip])
    }

    @MainActor func testInvalidEmail_failsValidation() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "not-an-email"
        vm.cardData = validCardData()
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.email])
    }

    @MainActor func testInvalidZip_failsInRequired() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        fillValidAddress(vm)
        vm.customerZipCode = "1234"
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }

    @MainActor func testClearError() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        vm.fieldErrors[.email] = "bad"
        vm.clearError(.email)
        XCTAssertNil(vm.fieldErrors[.email])
    }

    @MainActor func testSavedCardSelected_skipsCardValidation() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "tester@example.com"
        // No cardData filled — saved-card path should still pass.
        let saved = FrameObjects.PaymentMethod(id: "saved", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        vm.selectedCustomerPaymentOption = saved
        XCTAssertTrue(vm.validateAll(forSavedCard: true))
        XCTAssertNil(vm.fieldErrors[.card])
    }

    @MainActor func testSavedCardSelected_stillValidatesNameAndEmail() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        // Missing name/email
        XCTAssertFalse(vm.validateAll(forSavedCard: true))
        XCTAssertNotNil(vm.fieldErrors[.name])
        XCTAssertNotNil(vm.fieldErrors[.email])
    }

    @MainActor func testSingleName_failsValidation() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        vm.customerName = "OnlyOne"
        vm.customerEmail = "tester@example.com"
        vm.cardData = validCardData()
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.name])
    }

    @MainActor func testHasUsablePaymentInput_defaultFalse() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        // Default cardData has empty number and no saved card selected.
        XCTAssertFalse(vm.hasUsablePaymentInput)
    }

    @MainActor func testHasUsablePaymentInput_savedCardEnables() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        let saved = FrameObjects.PaymentMethod(id: "saved", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        vm.selectedCustomerPaymentOption = saved
        XCTAssertTrue(vm.hasUsablePaymentInput)
    }

    @MainActor func testHasUsablePaymentInput_validCardEnables() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .hidden)
        vm.cardData = validCardData()
        XCTAssertTrue(vm.hasUsablePaymentInput)
    }

    @MainActor func testSavedCardSelected_stillValidatesAddressInRequired() {
        let vm = FrameCheckoutViewModel(customerId: "", amount: 100, addressMode: .required)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "tester@example.com"
        // Address blank — should still error in required mode even on saved-card path.
        XCTAssertFalse(vm.validateAll(forSavedCard: true))
        XCTAssertNotNil(vm.fieldErrors[.addressLine1])
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }
}
