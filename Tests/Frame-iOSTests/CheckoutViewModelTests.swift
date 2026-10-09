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

    @MainActor func testLoadAccountPaymentMethods() async {
        FrameNetworking.shared.asyncURLSession = session

        // Nil accountId — no fetch, options stay nil.
        let viewModel = FrameCheckoutViewModel(accountId: nil, amount: 100)
        await viewModel.loadAccountPaymentMethods()
        XCTAssertNil(viewModel.accountPaymentOptions)

        // Without a secret key, a populated list response is ignored.
        FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout")
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let response = PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [paymentMethod])
        session.data = try? JSONEncoder().encode(response)
        let viewModelTwo = FrameCheckoutViewModel(accountId: "1", amount: 100)
        await viewModelTwo.loadAccountPaymentMethods()
        XCTAssertNil(viewModelTwo.accountPaymentOptions)
        XCTAssertTrue(viewModelTwo.didLoadAccountPaymentMethods)
    }

    @MainActor func testLoadAccountPaymentMethods_selectsFirstWhenSecretKeyIsConfigured() async {
        FrameNetworking.shared.asyncURLSession = session
        let pm1 = FrameObjects.PaymentMethod(id: "pm_1", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let pm2 = FrameObjects.PaymentMethod(id: "pm_2", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let response = PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [pm1, pm2])
        session.data = try? JSONEncoder().encode(response)
        FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout", secretKey: "sk_test_checkout")
        defer { FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout") }

        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100)
        await vm.loadAccountPaymentMethods()
        XCTAssertEqual(vm.accountPaymentOptions?.map(\.id), ["pm_1", "pm_2"])
        XCTAssertEqual(vm.selectedAccountPaymentOption?.id, "pm_1")
        XCTAssertTrue(vm.didLoadAccountPaymentMethods)
    }

    @MainActor func testSuppliedAccountAndPaymentMethods_areUsedWithoutASecretKey() async {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout")
        FrameNetworking.shared.asyncURLSession = session
        let fetched = FrameObjects.PaymentMethod(id: "fetched", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        session.data = try? JSONEncoder().encode(PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [fetched]))

        let supplied = FrameObjects.PaymentMethod(id: "supplied", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let individual = FrameObjects.IndividualAccount(
            name: FrameObjects.AccountNameInfo(firstName: "Ada", lastName: "Lovelace"),
            email: "ada@example.com",
            ssnLastFour: nil,
            phone: nil,
            phoneNumber: nil,
            phoneCountryCode: nil,
            address: nil,
            birthdate: nil
        )
        let account = FrameObjects.Account(
            id: "acc_1",
            object: "account",
            accountType: .individual,
            accountStatus: .active,
            profile: FrameObjects.AccountProfile(business: nil, individual: individual),
            created: 0,
            updated: 0,
            livemode: false
        )
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, account: account, paymentMethods: [supplied])
        await vm.loadAccountDetails()
        XCTAssertEqual(vm.customerName, "Ada Lovelace")
        XCTAssertEqual(vm.customerEmail, "ada@example.com")
        XCTAssertEqual(vm.accountPaymentOptions?.map(\.id), ["supplied"])
        XCTAssertEqual(vm.selectedAccountPaymentOption?.id, "supplied")
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
        vm.customerState = "CA"
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

        // Empty accountId — bails out.
        session.data = try? JSONEncoder().encode(FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard, status: .active))
        let viewModel = FrameCheckoutViewModel(accountId: "", amount: 100)
        viewModel.customerName = "Tester McTest"
        viewModel.customerEmail = "tester@example.com"
        viewModel.customerZipCode = ""
        let firstMethod = try? await viewModel.createPaymentMethod(accountId: "")
        XCTAssertNil(firstMethod)

        viewModel.customerCountry = AvailableCountry.defaultCountry
        viewModel.customerZipCode = "75115"
        viewModel.cardData = PaymentCardData()

        // No card data — validation fails.
        session.data = nil
        let secondMethod = try? await viewModel.createPaymentMethod(accountId: "acc_1")
        XCTAssertNil(secondMethod)

        viewModel.cardData = paymentCardData
        viewModel.customerZipCode = ""

        // Invalid zip — validation fails even with valid card.
        session.data = try? JSONEncoder().encode(FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard, status: .active))
        let thirdMethod = try? await viewModel.createPaymentMethod(accountId: "acc_1")
        XCTAssertNil(thirdMethod)

        fillValidAddress(viewModel)

        let billingAddress = FrameObjects.BillingAddress(country: viewModel.customerCountry.displayName, postalCode: viewModel.customerZipCode)
        let method = FrameObjects.PaymentMethod(id: "1", billing: billingAddress, type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard, status: .active)

        // Valid inputs — returns the new payment method's id.
        session.data = try? JSONEncoder().encode(method)
        let fourthMethod = try? await viewModel.createPaymentMethod(accountId: "acc_1")
        XCTAssertEqual(fourthMethod, "1")
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
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.addressLine1])
        XCTAssertNotNil(vm.fieldErrors[.city])
        XCTAssertNotNil(vm.fieldErrors[.state])
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }

    @MainActor func testOptional_allBlank_isValid() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .optional)
        fillValidCustomerInfo(vm)
        XCTAssertTrue(vm.validateAll(forSavedCard: false))
        XCTAssertNil(vm.fieldErrors[.addressLine1])
        XCTAssertNil(vm.fieldErrors[.zip])
    }

    @MainActor func testOptional_partialAddress_failsValidation() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .optional)
        fillValidCustomerInfo(vm)
        vm.customerCity = "Burbank" // partial fill triggers all-or-nothing
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.addressLine1])
        XCTAssertNotNil(vm.fieldErrors[.state])
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }

    @MainActor func testHidden_neverValidatesAddress() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        fillValidCustomerInfo(vm)
        // Even with garbage in address fields, hidden mode skips validation entirely.
        vm.customerCity = "x"
        vm.customerZipCode = "1"
        XCTAssertTrue(vm.validateAll(forSavedCard: false))
        XCTAssertNil(vm.fieldErrors[.zip])
    }

    @MainActor func testInvalidEmail_failsValidation() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "not-an-email"
        vm.cardData = validCardData()
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.email])
    }

    @MainActor func testInvalidZip_failsInRequired() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        fillValidAddress(vm)
        vm.customerZipCode = "1234"
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }

    @MainActor func testRequired_canadianAddress_isValid() {
        // Regression for FRA-6135: the checkout form offers a full country picker but used to
        // validate every address as US, so any non-US selection was unsubmittable.
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        fillValidAddress(vm)
        vm.customerCountry = AvailableCountry(alpha2Code: "CA", displayName: "Canada")
        vm.customerState = "ON"
        vm.customerZipCode = "M5V 2T6"
        XCTAssertTrue(vm.validateAll(forSavedCard: false))
        XCTAssertNil(vm.fieldErrors[.state])
        XCTAssertNil(vm.fieldErrors[.zip])
    }

    @MainActor func testRequired_usStateOnCanadianAddress_failsValidation() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        fillValidAddress(vm)
        vm.customerCountry = AvailableCountry(alpha2Code: "CA", displayName: "Canada")
        vm.customerState = "TX"
        vm.customerZipCode = "M5V 2T6"
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.state])
    }

    @MainActor func testRequired_unlistedCountry_acceptsFreeTextRegion() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        fillValidAddress(vm)
        vm.customerCountry = AvailableCountry(alpha2Code: "GB", displayName: "United Kingdom")
        vm.customerState = "Greater London"
        vm.customerZipCode = "EC1A 1BB"
        XCTAssertTrue(vm.validateAll(forSavedCard: false))
    }

    @MainActor func testRequired_usZipPlusFour_isAccepted() {
        // The checkout form now shares `validatePostalCode`, which accepts ZIP+4.
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        fillValidCustomerInfo(vm)
        fillValidAddress(vm)
        vm.customerZipCode = "75115-1234"
        XCTAssertTrue(vm.validateAll(forSavedCard: false))
    }

    @MainActor func testClearError() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        vm.fieldErrors[.email] = "bad"
        vm.clearError(.email)
        XCTAssertNil(vm.fieldErrors[.email])
    }

    @MainActor func testSavedCardSelected_skipsCardValidation() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "tester@example.com"
        // No cardData filled — saved-card path should still pass.
        let saved = FrameObjects.PaymentMethod(id: "saved", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        vm.selectedAccountPaymentOption = saved
        XCTAssertTrue(vm.validateAll(forSavedCard: true))
        XCTAssertNil(vm.fieldErrors[.card])
    }

    @MainActor func testSavedCardSelected_stillValidatesNameAndEmail() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        // Missing name/email
        XCTAssertFalse(vm.validateAll(forSavedCard: true))
        XCTAssertNotNil(vm.fieldErrors[.name])
        XCTAssertNotNil(vm.fieldErrors[.email])
    }

    @MainActor func testSingleName_failsValidation() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        vm.customerName = "OnlyOne"
        vm.customerEmail = "tester@example.com"
        vm.cardData = validCardData()
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.name])
    }

    @MainActor func testHasUsablePaymentInput_defaultFalse() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        // Default cardData has empty number and no saved card selected.
        XCTAssertFalse(vm.hasUsablePaymentInput)
    }

    @MainActor func testHasUsablePaymentInput_savedCardEnables() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        let saved = FrameObjects.PaymentMethod(id: "saved", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        vm.selectedAccountPaymentOption = saved
        XCTAssertTrue(vm.hasUsablePaymentInput)
    }

    @MainActor func testHasUsablePaymentInput_validCardEnables() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .hidden)
        vm.cardData = validCardData()
        XCTAssertTrue(vm.hasUsablePaymentInput)
    }

    @MainActor func testSavedCardSelected_skipsAddressValidationEvenInRequired() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "tester@example.com"
        // Saved-card path skips address validation regardless of addressMode, because
        // the saved PM already carries a billing address server-side and the UI hides
        // those fields.
        XCTAssertTrue(vm.validateAll(forSavedCard: true))
        XCTAssertNil(vm.fieldErrors[.addressLine1])
        XCTAssertNil(vm.fieldErrors[.zip])
    }

    @MainActor func testSavedCardSelected_skipsAddressValidationInOptionalWithPartialInput() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .optional)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "tester@example.com"
        // Partial address input would normally trip all-or-nothing optional validation —
        // but the saved-card path skips it entirely.
        vm.customerCity = "Burbank"
        XCTAssertTrue(vm.validateAll(forSavedCard: true))
        XCTAssertNil(vm.fieldErrors[.addressLine1])
        XCTAssertNil(vm.fieldErrors[.zip])
    }

    @MainActor func testSwitchingBackToNewCard_reRequiresAddressInRequired() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        vm.customerName = "Tester McTest"
        vm.customerEmail = "tester@example.com"
        // Saved path: passes with no address.
        XCTAssertTrue(vm.validateAll(forSavedCard: true))
        // Back to new-card mode: address required.
        XCTAssertFalse(vm.validateAll(forSavedCard: false))
        XCTAssertNotNil(vm.fieldErrors[.addressLine1])
        XCTAssertNotNil(vm.fieldErrors[.zip])
    }

    @MainActor func testLoadAccountPaymentMethods_doesNotSelectFromAListResponse() async {
        FrameNetworking.shared.asyncURLSession = session
        let pm1 = FrameObjects.PaymentMethod(id: "pm_1", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let pm2 = FrameObjects.PaymentMethod(id: "pm_2", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let response = PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [pm1, pm2])
        session.data = try? JSONEncoder().encode(response)

        FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout")
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100)
        await vm.loadAccountPaymentMethods()
        XCTAssertNil(vm.selectedAccountPaymentOption)
        XCTAssertTrue(vm.didLoadAccountPaymentMethods)
    }

    @MainActor func testLoadAccountPaymentMethods_doesNotAutoSelectWhenEmpty() async {
        FrameNetworking.shared.asyncURLSession = session
        let response = PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [])
        session.data = try? JSONEncoder().encode(response)

        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100)
        await vm.loadAccountPaymentMethods()
        XCTAssertNil(vm.selectedAccountPaymentOption)
    }

    @MainActor func testLoadAccountPaymentMethods_respectsExistingSelection() async {
        FrameNetworking.shared.asyncURLSession = session
        let pm1 = FrameObjects.PaymentMethod(id: "pm_1", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let response = PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [pm1])
        session.data = try? JSONEncoder().encode(response)

        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100)
        let preselected = FrameObjects.PaymentMethod(id: "user_choice", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        vm.selectedAccountPaymentOption = preselected
        await vm.loadAccountPaymentMethods()
        XCTAssertEqual(vm.selectedAccountPaymentOption?.id, "user_choice")
    }

    @MainActor func testLoadAccountPaymentMethods_doesNotAutoSelectWhenUserHasStartedTypingCard() async {
        FrameNetworking.shared.asyncURLSession = session
        let pm1 = FrameObjects.PaymentMethod(id: "pm_1", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let response = PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [pm1])
        session.data = try? JSONEncoder().encode(response)

        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100)
        var typed = PaymentCardData()
        typed.card.number = "4242"
        vm.cardData = typed
        await vm.loadAccountPaymentMethods()
        // Late-arriving response must not yank input out from under a user mid-type.
        XCTAssertNil(vm.selectedAccountPaymentOption)
    }

    @MainActor func testClearNewCardFieldErrors_clearsOnlyNewCardKeys() {
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, addressMode: .required)
        vm.fieldErrors = [
            .name: "name err",
            .email: "email err",
            .card: "card err",
            .addressLine1: "addr err",
            .city: "city err",
            .state: "state err",
            .zip: "zip err",
            .country: "country err"
        ]
        vm.clearNewCardFieldErrors()
        XCTAssertEqual(vm.fieldErrors[.name], "name err")
        XCTAssertEqual(vm.fieldErrors[.email], "email err")
        XCTAssertNil(vm.fieldErrors[.card])
        XCTAssertNil(vm.fieldErrors[.addressLine1])
        XCTAssertNil(vm.fieldErrors[.city])
        XCTAssertNil(vm.fieldErrors[.state])
        XCTAssertNil(vm.fieldErrors[.zip])
        XCTAssertNil(vm.fieldErrors[.country])
    }

    @MainActor func testCheckoutClientSecret_refreshesWhenExpiredThenLoadsProfileAndCards() async {
        let sequenced = SequencedCheckoutSession(failFirstAccountRead: false)
        FrameNetworking.shared.asyncURLSession = sequenced
        FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout", secretKey: "sk_test_checkout")
        defer { FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout") }

        let secret = FrameCheckoutClientSecret(clientSecret: "chk_sess_old", expiresAt: Date(timeIntervalSince1970: 0))
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, checkoutClientSecret: secret)
        await vm.loadAccountDetails()

        XCTAssertEqual(vm.customerName, "Ada Lovelace")
        XCTAssertEqual(vm.customerEmail, "ada@example.com")
        XCTAssertEqual(vm.accountPaymentOptions?.map(\.id), ["pm_1"])
        XCTAssertEqual(vm.selectedAccountPaymentOption?.card?.lastFourDigits, "4242")
        XCTAssertEqual(secret.clientSecret, "chk_sess_new")
        XCTAssertEqual(
            sequenced.authorizations.filter { $0.contains("sk_test_checkout") || $0.contains("chk_sess") },
            ["Bearer sk_test_checkout", "Bearer chk_sess_new", "Bearer chk_sess_new"]
        )
        let refreshBody = String(data: sequenced.checkoutSessionBodies.first ?? Data(), encoding: .utf8)
        XCTAssertTrue(refreshBody?.contains("\"value\":100") == true)
    }

    @MainActor func testCheckoutClientSecret_refreshesAfterUnauthorizedRead() async {
        let sequenced = SequencedCheckoutSession(failFirstAccountRead: true)
        FrameNetworking.shared.asyncURLSession = sequenced
        FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout", secretKey: "sk_test_checkout")
        defer { FrameNetworking.shared.initialize(publishableKey: "pk_test_checkout") }

        let secret = FrameCheckoutClientSecret(clientSecret: "chk_sess_old", expiresAt: Date(timeIntervalSince1970: 2_000_000_000))
        let vm = FrameCheckoutViewModel(accountId: "acc_1", amount: 100, checkoutClientSecret: secret)
        await vm.loadAccountDetails()

        XCTAssertEqual(vm.customerName, "Ada Lovelace")
        XCTAssertEqual(secret.clientSecret, "chk_sess_new")
        let checkoutCalls = sequenced.authorizations.filter { $0.contains("chk_sess") || $0.contains("sk_test_checkout") }
        XCTAssertEqual(checkoutCalls.first, "Bearer chk_sess_old")
        XCTAssertTrue(checkoutCalls.contains("Bearer sk_test_checkout"))
        XCTAssertTrue(checkoutCalls.contains("Bearer chk_sess_new"))
    }

    static let checkoutSessionJSON = Data("""
    {"id":"cs_1","account_id":"acc_1","client_secret":"chk_sess_new","object":"checkout_session","expires_at":2000000000,"livemode":false}
    """.utf8)

    static let checkoutAccountJSON = Data("""
    {"id":"acc_1","object":"account","profile":{"individual":{"name":{"first_name":"Ada","last_name":"Lovelace"},"email":"ada@example.com"}}}
    """.utf8)

    static let checkoutMethodsJSON = Data("""
    {"data":[{"id":"pm_1","object":"payment_method","type":"card","status":"active","card":{"brand":"visa","last_four":"4242","exp_month":"12","exp_year":"2027"}}]}
    """.utf8)
}

private final class SequencedCheckoutSession: URLSessionProtocol {
    let failFirstAccountRead: Bool
    private var didFailAccountRead = false
    private(set) var authorizations: [String] = []
    private(set) var checkoutSessionBodies: [Data] = []

    init(failFirstAccountRead: Bool) {
        self.failFirstAccountRead = failFirstAccountRead
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        authorizations.append(request.value(forHTTPHeaderField: "Authorization") ?? "")
        let path = request.url?.path ?? ""
        let status: Int
        let body: Data
        if path == "/v1/checkout_sessions" {
            checkoutSessionBodies.append(request.httpBody ?? Data())
            status = 200
            body = CheckoutViewModelTests.checkoutSessionJSON
        } else if path.hasSuffix("/payment_methods") {
            status = 200
            body = CheckoutViewModelTests.checkoutMethodsJSON
        } else if path.hasPrefix("/v1/accounts/") {
            if failFirstAccountRead, !didFailAccountRead {
                didFailAccountRead = true
                status = 401
                body = Data("{\"error\":\"Invalid or expired client secret.\"}".utf8)
            } else {
                status = 200
                body = CheckoutViewModelTests.checkoutAccountJSON
            }
        } else {
            status = 200
            body = Data("{}".utf8)
        }
        let response = HTTPURLResponse(url: request.url ?? URL(string: "https://api.framepayments.com")!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}
