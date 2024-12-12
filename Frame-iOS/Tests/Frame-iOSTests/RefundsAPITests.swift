//
//  Test.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/7/24.
//

import XCTest
@testable import Frame_iOS

final class RefundsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/charge_intents")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    
    func testCreateRefund() async {
        let request = RefundRequests.CreateRefundRequest(amount: 100, charge: "", chargeIntent: "", reason: "")
        let creation = try? await RefundsAPI(mockSession: session).createRefund(request: request)
        XCTAssertNil(creation)
        
        do {
            let refund = FrameObjects.Refund(id: "1", amount: 100, object: "", created: 0, updated: 0)
            session.data = try JSONEncoder().encode(refund)
            let creationTwo = try await RefundsAPI(mockSession: session).createRefund(request: request)
            XCTAssertNotNil(creationTwo)
            XCTAssertEqual(creationTwo?.amount, 100)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetRefunds() async {
        let refund = try? await RefundsAPI(mockSession: session).getRefunds(chargeId: "", chargeIntentId: "")
        XCTAssertNil(refund)
        
        let refundTwo = try? await RefundsAPI(mockSession: session).getRefunds(chargeId: "1", chargeIntentId: "2")
        XCTAssertNil(refundTwo)
        
        do {
            let refund = FrameObjects.Refund(id: "1", amount: 100, object: "", created: 0, updated: 0)
            let refundTwo = FrameObjects.Refund(id: "2", amount: 1000, object: "", created: 0, updated: 0)
            session.data = try JSONEncoder().encode(RefundResponses.ListRefundsResponse(meta: nil, data: [refund, refundTwo]))
            let refunds = try await RefundsAPI(mockSession: session).getRefunds(chargeId: "1", chargeIntentId: "2")
            XCTAssertNotNil(refunds)
            XCTAssertEqual(refunds?.count, 2)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetRefund() async {
        let refund = try? await RefundsAPI(mockSession: session).getRefundWith(refundId: "")
        XCTAssertNil(refund)
        
        let refundTwo = try? await RefundsAPI(mockSession: session).getRefundWith(refundId: "123")
        XCTAssertNil(refundTwo)
        
        do {
            let refund = FrameObjects.Refund(id: "1", amount: 100, object: "", created: 0, updated: 0)
            session.data = try JSONEncoder().encode(refund)
            let refundThree = try await RefundsAPI(mockSession: session).getRefundWith(refundId: "1234")
            XCTAssertNotNil(refundThree)
            XCTAssertEqual(refundThree?.amount, 100)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCancelRefund() async {
        let cancellation = try? await RefundsAPI(mockSession: session).cancelRefund(refundId: "")
        XCTAssertNil(cancellation)
        
        let cancellationTwo = try? await RefundsAPI(mockSession: session).cancelRefund(refundId: "123")
        XCTAssertNil(cancellationTwo)
        
        do {
            let refund = FrameObjects.Refund(id: "1", amount: 100, object: "", created: 0, updated: 0)
            session.data = try JSONEncoder().encode(refund)
            let cancellationThree = try await RefundsAPI(mockSession: session).cancelRefund(refundId: "1234")
            XCTAssertNotNil(cancellationThree)
            XCTAssertEqual(cancellationThree?.amount, 100)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
