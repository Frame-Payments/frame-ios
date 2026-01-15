//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/6/24.
//

import XCTest
@testable import Frame

final class ChargeIntentsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/charge_intents")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    
    let chargeIntentResponse = FrameObjects.ChargeIntent(id: "1", currency: "USD", shipping: FrameObjects.BillingAddress(postalCode: "99999"), status: .pending,
                                                         authorizationMode: .automatic, object: "", amount: 10, created: 0, updated: 0, livemode: true)
    
    func testCreateChargeIntent() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = ChargeIntentsRequests.CreateChargeIntentRequest(amount: 10, currency: "USD", confirm: true)
        XCTAssertNotNil(request.amount)
        XCTAssertNotNil(request.currency)
        XCTAssertNotNil(request.confirm)
        
        let intent = try? await ChargeIntentsAPI.createChargeIntent(request: request).0
        XCTAssertNil(intent)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntentResponse)
            let (secondIntent, _) = try await ChargeIntentsAPI.createChargeIntent(request: request)
            XCTAssertNotNil(secondIntent)
            XCTAssertEqual(secondIntent?.shipping, chargeIntentResponse.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCaptureChargeIntent() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = ChargeIntentsRequests.CaptureChargeIntentRequest(amountCapturedCents: 0)
        XCTAssertNotNil(request.amountCapturedCents)
        
        let capture = try? await ChargeIntentsAPI.captureChargeIntent(intentId: "", request: request).0
        XCTAssertNil(capture)
        
        let secondCapture = try? await ChargeIntentsAPI.captureChargeIntent(intentId: "123", request: request).0
        XCTAssertNil(secondCapture)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntentResponse)
            let (thirdCapture, _) = try await ChargeIntentsAPI.captureChargeIntent(intentId: "1234", request: request)
            XCTAssertNotNil(thirdCapture)
            XCTAssertEqual(thirdCapture?.shipping, chargeIntentResponse.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testConfirmChargeIntent() async  {
        FrameNetworking.shared.asyncURLSession = session
        let confirmation = try? await ChargeIntentsAPI.confirmChargeIntent(intentId: "").0
        XCTAssertNil(confirmation)
        
        let confirmationTwo = try? await ChargeIntentsAPI.confirmChargeIntent(intentId: "123").0
        XCTAssertNil(confirmationTwo)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntentResponse)
            let (confirmationThree, _) = try await ChargeIntentsAPI.confirmChargeIntent(intentId: "1234")
            XCTAssertNotNil(confirmationThree)
            XCTAssertEqual(confirmationThree?.shipping, chargeIntentResponse.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCancelChargeIntent() async  {
        FrameNetworking.shared.asyncURLSession = session
        let cancellation = try? await ChargeIntentsAPI.cancelChargeIntent(intentId: "").0
        XCTAssertNil(cancellation)
        
        let cancellationTwo = try? await ChargeIntentsAPI.cancelChargeIntent(intentId: "123").0
        XCTAssertNil(cancellationTwo)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntentResponse)
            let (cancellationThree, _) = try await ChargeIntentsAPI.cancelChargeIntent(intentId: "1234")
            XCTAssertNotNil(cancellationThree)
            XCTAssertEqual(cancellationThree?.shipping, chargeIntentResponse.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetAllChargeIntents() async {
        FrameNetworking.shared.asyncURLSession = session
        let intentsOne = try? await ChargeIntentsAPI.getAllChargeIntents().0
        XCTAssertNil(intentsOne)
        
        let shippingAddress = FrameObjects.BillingAddress(postalCode: "99999")
        let chargeIntentTwo = FrameObjects.ChargeIntent(id: "2", currency: "EUR", shipping: shippingAddress, status: .canceled,
                                                        authorizationMode: .automatic, object: "", amount: 100, created: 0, updated: 0, livemode: false)
        do {
            session.data = try JSONEncoder().encode(ChargeIntentResponses.ListChargeIntentsResponse(meta: nil, data: [chargeIntentResponse, chargeIntentTwo]))
            let (intentsTwo, _) = try await ChargeIntentsAPI.getAllChargeIntents()

            XCTAssertNotNil(intentsTwo)
            XCTAssertEqual(intentsTwo?.data?[0].currency, chargeIntentResponse.currency)
            XCTAssertEqual(intentsTwo?.data?[1].currency, chargeIntentTwo.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetChargeIntent() async  {
        FrameNetworking.shared.asyncURLSession = session
        let intentOne = try? await ChargeIntentsAPI.getChargeIntent(intentId: "").0
        XCTAssertNil(intentOne)
        
        let intentTwo = try? await ChargeIntentsAPI.getChargeIntent(intentId: "123").0
        XCTAssertNil(intentTwo)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntentResponse)
            let (intentThree, _) = try await ChargeIntentsAPI.getChargeIntent(intentId: "1234")
            XCTAssertNotNil(intentThree)
            XCTAssertEqual(intentThree?.shipping, chargeIntentResponse.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateChargeIntent() async  {
        FrameNetworking.shared.asyncURLSession = session
        let request = ChargeIntentsRequests.UpdateChargeIntentRequest()
        let intentOne = try? await ChargeIntentsAPI.updateChargeIntent(intentId: "", request: request).0
        XCTAssertNil(intentOne)
        
        let intentTwo = try? await ChargeIntentsAPI.updateChargeIntent(intentId: "123", request: request).0
        XCTAssertNil(intentTwo)
        
        do {
            session.data = try JSONEncoder().encode(chargeIntentResponse)
            let (intentThree, _) = try await ChargeIntentsAPI.updateChargeIntent(intentId: "1234", request: request)
            XCTAssertNotNil(intentThree)
            XCTAssertEqual(intentThree?.shipping, chargeIntentResponse.shipping)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
