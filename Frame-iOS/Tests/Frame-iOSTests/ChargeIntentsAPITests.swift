//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/6/24.
//

import XCTest
@testable import Frame_iOS

final class ChargeIntentsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/charge_intents")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    
    func testCreateChargeIntent() async {
        let request = ChargeIntentsRequests.CreateChargeIntentRequest(amount: 0, currency: "USD", confirm: true)
        XCTAssertNotNil(request.amount)
        XCTAssertNotNil(request.currency)
        XCTAssertNotNil(request.confirm)
        
        let intent = try? await ChargeIntentsAPI(mockSession: session).createChargeIntent(request: request)
        XCTAssertNil(intent)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntent = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: shippingAddress, status: .pending,
                                                     object: "", amount: 10, created: 0, updated: 0, livemode: true)
        XCTAssertNotNil(chargeIntent.shipping)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntent)
            let secondIntent = try await ChargeIntentsAPI(mockSession: session).createChargeIntent(request: request)
            XCTAssertNotNil(secondIntent)
            XCTAssertEqual(secondIntent?.shipping, chargeIntent.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCaptureChargeIntent() async  {
        let request = ChargeIntentsRequests.CaptureChargeIntentRequest(amountCapturedCents: 0)
        XCTAssertNotNil(request.amountCapturedCents)
        
        let capture = try? await ChargeIntentsAPI(mockSession: session).captureChargeIntent(intentId: "", request: request)
        XCTAssertNil(capture)
        
        let secondCapture = try? await ChargeIntentsAPI(mockSession: session).captureChargeIntent(intentId: "123", request: request)
        XCTAssertNil(secondCapture)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntent = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: shippingAddress, status: .pending,
                                                     object: "", amount: 10, created: 0, updated: 0, livemode: true)
        do {
            session.data = try JSONEncoder().encode(chargeIntent)
            let thirdCapture = try await ChargeIntentsAPI(mockSession: session).captureChargeIntent(intentId: "1234", request: request)
            XCTAssertNotNil(thirdCapture)
            XCTAssertEqual(thirdCapture?.shipping, chargeIntent.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testConfirmChargeIntent() async  {
        let confirmation = try? await ChargeIntentsAPI(mockSession: session).confirmChargeIntent(intentId: "")
        XCTAssertNil(confirmation)
        
        let confirmationTwo = try? await ChargeIntentsAPI(mockSession: session).confirmChargeIntent(intentId: "123")
        XCTAssertNil(confirmationTwo)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntent = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: shippingAddress, status: .pending,
                                                     object: "", amount: 10, created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntent)
            let confirmationThree = try await ChargeIntentsAPI(mockSession: session).confirmChargeIntent(intentId: "1234")
            XCTAssertNotNil(confirmationThree)
            XCTAssertEqual(confirmationThree?.shipping, chargeIntent.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCancelChargeIntent() async  {
        let cancellation = try? await ChargeIntentsAPI(mockSession: session).cancelChargeIntent(intentId: "")
        XCTAssertNil(cancellation)
        
        let cancellationTwo = try? await ChargeIntentsAPI(mockSession: session).cancelChargeIntent(intentId: "123")
        XCTAssertNil(cancellationTwo)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntent = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: shippingAddress, status: .pending,
                                                     object: "", amount: 10, created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntent)
            let cancellationThree = try await ChargeIntentsAPI(mockSession: session).cancelChargeIntent(intentId: "1234")
            XCTAssertNotNil(cancellationThree)
            XCTAssertEqual(cancellationThree?.shipping, chargeIntent.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetAllChargeIntents() async  {
        let intentsOne = try? await ChargeIntentsAPI(mockSession: session).getAllChargeIntents()
        XCTAssertNil(intentsOne)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntent = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: shippingAddress, status: .pending,
                                                     object: "", amount: 10, created: 0, updated: 0, livemode: true)
        
        let chargeIntentTwo = FrameObjects.ChargeIntent(id: "2", currency: "EUR", shipping: shippingAddress, status: .canceled,
                                                     object: "", amount: 100, created: 0, updated: 0, livemode: false)
        do {
            session.data = try JSONEncoder().encode(ChargeIntentResponses.ListChargeIntentsResponse(meta: nil, data: [chargeIntent, chargeIntentTwo]))
            let intentsTwo = try await ChargeIntentsAPI(mockSession: session).getAllChargeIntents()
            XCTAssertNotNil(intentsTwo)
            XCTAssertEqual(intentsTwo?[0].currency, chargeIntent.currency)
            XCTAssertEqual(intentsTwo?[1].currency, chargeIntentTwo.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetChargeIntent() async  {
        let intentOne = try? await ChargeIntentsAPI(mockSession: session).getChargeIntent(intentId: "")
        XCTAssertNil(intentOne)
        
        let intentTwo = try? await ChargeIntentsAPI(mockSession: session).getChargeIntent(intentId: "123")
        XCTAssertNil(intentTwo)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntent = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: shippingAddress, status: .pending,
                                                     object: "", amount: 10, created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntent)
            let intentThree = try await ChargeIntentsAPI(mockSession: session).getChargeIntent(intentId: "1234")
            XCTAssertNotNil(intentThree)
            XCTAssertEqual(intentThree?.shipping, chargeIntent.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateChargeIntent() async  {
        let request = ChargeIntentsRequests.UpdateChargeIntentRequest()
        let intentOne = try? await ChargeIntentsAPI(mockSession: session).updateChargeIntent(intentId: "", request: request)
        XCTAssertNil(intentOne)
        
        let intentTwo = try? await ChargeIntentsAPI(mockSession: session).updateChargeIntent(intentId: "123", request: request)
        XCTAssertNil(intentTwo)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntent = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: shippingAddress, status: .pending,
                                                     object: "", amount: 10, created: 0, updated: 0, livemode: true)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntent)
            let intentThree = try await ChargeIntentsAPI(mockSession: session).updateChargeIntent(intentId: "1234", request: request)
            XCTAssertNotNil(intentThree)
            XCTAssertEqual(intentThree?.shipping, chargeIntent.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
