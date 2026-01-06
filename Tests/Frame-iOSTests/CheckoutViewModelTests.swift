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
        let viewModel = FrameCheckoutViewModel()
        await viewModel.loadCustomerPaymentMethods(customerId: "", amount: 100, forTesting: true)
        XCTAssertNil(viewModel.customerPaymentOptions)
        
        // Test with valid customer ID with no payment methods
        await viewModel.loadCustomerPaymentMethods(customerId: "1", amount: 100, forTesting: true)
        XCTAssertNil(viewModel.customerPaymentOptions)
        
        // Test with valid customer ID with payment method
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: false)
        let customer = FrameObjects.Customer(id: "1", livemode: false, name: "Tester", paymentMethods: [paymentMethod])
        
        session.data = try? JSONEncoder().encode(customer)
        await viewModel.loadCustomerPaymentMethods(customerId: "1", amount: 100, forTesting: true)
        XCTAssertNotNil(viewModel.customerPaymentOptions)
        XCTAssertEqual(viewModel.customerPaymentOptions?.first?.id, "1")
    }
    
    @MainActor func testCreatePaymentMethod() async {
        FrameNetworking.shared.asyncURLSession = session
        
        var paymentCardData = PaymentCardData()
        paymentCardData.card.number = "4242424242424242"
        paymentCardData.card.expMonth = "12"
        paymentCardData.card.expYear = "2025"
        paymentCardData.card.cvc = "123"
        paymentCardData.card.lastFour = "4242"
        
        let paymentCard = FrameObjects.PaymentCard(brand: paymentCardData.card.type?.brand ?? "",
                                                   expirationMonth: paymentCardData.card.expMonth,
                                                   expirationYear: paymentCardData.card.expYear,
                                                   currency: "USD",
                                                   lastFourDigits: paymentCardData.card.lastFour)
        
        // Test with no customer country or customer Zip Code
        session.data = try? JSONEncoder().encode(FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard))
        let viewModel = FrameCheckoutViewModel()
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
        session.data = try? JSONEncoder().encode(FrameObjects.PaymentMethod(id: "1", type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard))
        let thirdMethod = try? await viewModel.createPaymentMethod()
        XCTAssertNil(thirdMethod?.paymentId)
        XCTAssertNil(thirdMethod?.customerId)
        
        viewModel.customerAddressLine1 = "123 Main St"
        viewModel.customerCity = "Burbank"
        viewModel.customerCountry = AvailableCountry.defaultCountry
        viewModel.customerState = "California"
        viewModel.customerZipCode = "75115"
        
        let billingAddress = FrameObjects.BillingAddress(country: viewModel.customerCountry.displayName, postalCode: viewModel.customerZipCode)
        let method = FrameObjects.PaymentMethod(id: "1", billing: billingAddress, type: .card, object: "", created: 0, updated: 0, livemode: true, card: paymentCard)
        
        // Test with valid zipCode and valid card data
        session.data = try? JSONEncoder().encode(method)
        let fourthMethod = try? await viewModel.createPaymentMethod(customerId: "111")
        XCTAssertNotNil(fourthMethod)
        XCTAssertEqual(fourthMethod?.customerId, "111")
    }
}
