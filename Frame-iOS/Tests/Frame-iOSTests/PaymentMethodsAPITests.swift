//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/10/24.
//

import XCTest
@testable import Frame_iOS

final class PaymentMethodsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/payment_methods")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    func testGetPaymentMethods() async {
        let receivedMethod = try? await PaymentMethodsAPI(mockSession: session).getPaymentMethods()
        XCTAssertNil(receivedMethod)
        
        let secondReceivedMethod = try? await PaymentMethodsAPI(mockSession: session).getPaymentMethods()
        XCTAssertNil(secondReceivedMethod)
        
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", customer: "123456", type: "card", object: "", created: 0, updated: 0, livemode: true)
        let secondPaymentMethod = FrameObjects.PaymentMethod(id: "2", customer: "123456", type: "card", object: "", created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [paymentMethod, secondPaymentMethod]))
            let thirdReceivedMethod = try await PaymentMethodsAPI(mockSession: session).getPaymentMethods()
            XCTAssertNotNil(thirdReceivedMethod)
            XCTAssertEqual(thirdReceivedMethod?[0].customer, paymentMethod.customer)
            XCTAssertEqual(thirdReceivedMethod?[1].customer, paymentMethod.customer)
            XCTAssertEqual(thirdReceivedMethod?[0].customer, secondPaymentMethod.customer)
            XCTAssertEqual(thirdReceivedMethod?[1].customer, secondPaymentMethod.customer)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetPaymentMethod() async {
        let receivedMethod = try? await PaymentMethodsAPI(mockSession: session).getPaymentMethodWith(paymentMethodId: "")
        XCTAssertNil(receivedMethod)
        
        let secondReceivedMethod = try? await PaymentMethodsAPI(mockSession: session).getPaymentMethodWith(paymentMethodId: "123")
        XCTAssertNil(secondReceivedMethod)
        
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", type: "card", object: "", created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(paymentMethod)
            let thirdReceivedMethod = try await PaymentMethodsAPI(mockSession: session).getPaymentMethodWith(paymentMethodId: paymentMethod.id)
            XCTAssertNotNil(thirdReceivedMethod)
            XCTAssertEqual(thirdReceivedMethod?.type, paymentMethod.type)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomerPaymentMethod() async {
        let receivedMethod = try? await PaymentMethodsAPI(mockSession: session).getPaymentMethodsWithCustomer(customerId: "")
        XCTAssertNil(receivedMethod)
        
        let secondReceivedMethod = try? await PaymentMethodsAPI(mockSession: session).getPaymentMethodsWithCustomer(customerId: "123")
        XCTAssertNil(secondReceivedMethod)
        
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", customer: "123456", type: "card", object: "", created: 0, updated: 0, livemode: true)
        let secondPaymentMethod = FrameObjects.PaymentMethod(id: "2", customer: "123456", type: "card", object: "", created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [paymentMethod, secondPaymentMethod]))
            let thirdReceivedMethod = try await PaymentMethodsAPI(mockSession: session).getPaymentMethodsWithCustomer(customerId: paymentMethod.customer ?? "")
            XCTAssertNotNil(thirdReceivedMethod)
            XCTAssertEqual(thirdReceivedMethod?[0].customer, paymentMethod.customer)
            XCTAssertEqual(thirdReceivedMethod?[1].customer, paymentMethod.customer)
            XCTAssertEqual(thirdReceivedMethod?[0].customer, secondPaymentMethod.customer)
            XCTAssertEqual(thirdReceivedMethod?[1].customer, secondPaymentMethod.customer)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCreatePaymentMethod() async {
        let request = PaymentMethodRequest.CreatePaymentMethodRequest(type: "card", cardNumber: "44444444444444444", expMonth: "08", expYear: "2021",
                                                                      cvc: "333", customer: nil, billing: nil)
        let receivedMethod = try? await PaymentMethodsAPI(mockSession: session).createPaymentMethod(request: request)
        XCTAssertNil(receivedMethod)
        
        let secondReceivedMethod = try? await PaymentMethodsAPI(mockSession: session).createPaymentMethod(request: request)
        XCTAssertNil(secondReceivedMethod)
        
        let billing = FrameObjects.BillingAddress(postalCode: "55555")
        let card = FrameObjects.PaymentCard(brand: "visa", expirationMonth: "08", expirationYear: "2021", currency: "USD", lastFourDigits: "1212")
        
        var paymentMethod = FrameObjects.PaymentMethod(id: "1", customer: "123456", type: "card", object: "", created: 0, updated: 0, livemode: true)
        XCTAssertNil(paymentMethod.billing)
        XCTAssertNil(paymentMethod.card)
        
        paymentMethod.billing = billing
        paymentMethod.card = card
        
        XCTAssertNotNil(paymentMethod.billing)
        XCTAssertNotNil(paymentMethod.card)
        
        do {
            session.data = try JSONEncoder().encode(paymentMethod)
            let thirdReceivedMethod = try await PaymentMethodsAPI(mockSession: session).createPaymentMethod(request: request)
            XCTAssertNotNil(thirdReceivedMethod)
            XCTAssertEqual(thirdReceivedMethod?.card, paymentMethod.card)
            XCTAssertEqual(thirdReceivedMethod?.billing, paymentMethod.billing)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdatePaymentMethod() async {
        let request = PaymentMethodRequest.UpdatePaymentMethodRequest()
        let receivedMethod = try? await PaymentMethodsAPI(mockSession: session).updatePaymentMethodWith(paymentMethodId: "", request: request)
        XCTAssertNil(receivedMethod)
        
        let secondReceivedMethod = try? await PaymentMethodsAPI(mockSession: session).updatePaymentMethodWith(paymentMethodId: "123", request: request)
        XCTAssertNil(secondReceivedMethod)
        
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", type: "card", object: "", created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(paymentMethod)
            let thirdReceivedMethod = try await PaymentMethodsAPI(mockSession: session).updatePaymentMethodWith(paymentMethodId: paymentMethod.id, request: request)
            XCTAssertNotNil(thirdReceivedMethod)
            XCTAssertEqual(thirdReceivedMethod?.type, paymentMethod.type)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testAttachPaymentMethod() async {
        let request = PaymentMethodRequest.AttachPaymentMethodRequest(customer: "")
        let receivedMethod = try? await PaymentMethodsAPI(mockSession: session).attachPaymentMethodWith(paymentMethodId: "", request: request)
        XCTAssertNil(receivedMethod)
        
        let secondReceivedMethod = try? await PaymentMethodsAPI(mockSession: session).attachPaymentMethodWith(paymentMethodId: "123", request: request)
        XCTAssertNil(secondReceivedMethod)
        
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", type: "card", object: "", created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(paymentMethod)
            let thirdReceivedMethod = try await PaymentMethodsAPI(mockSession: session).attachPaymentMethodWith(paymentMethodId: paymentMethod.id, request: request)
            XCTAssertNotNil(thirdReceivedMethod)
            XCTAssertEqual(thirdReceivedMethod?.type, paymentMethod.type)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testDetachPaymentMethod() async {
        let receivedMethod = try? await PaymentMethodsAPI(mockSession: session).detachPaymentMethodWith(paymentMethodId: "")
        XCTAssertNil(receivedMethod)
        
        let secondReceivedMethod = try? await PaymentMethodsAPI(mockSession: session).detachPaymentMethodWith(paymentMethodId: "123")
        XCTAssertNil(secondReceivedMethod)
        
        let paymentMethod = FrameObjects.PaymentMethod(id: "1", type: "card", object: "", created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(paymentMethod)
            let thirdReceivedMethod = try await PaymentMethodsAPI(mockSession: session).detachPaymentMethodWith(paymentMethodId: paymentMethod.id)
            XCTAssertNotNil(thirdReceivedMethod)
            XCTAssertEqual(thirdReceivedMethod?.type, paymentMethod.type)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
