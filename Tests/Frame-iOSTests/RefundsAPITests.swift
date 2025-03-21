//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/7/24.
//

import XCTest
@testable import Frame_iOS

final class RefundsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/refunds")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    
    func testCreateRefund() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = RefundRequests.CreateRefundRequest(amount: 100, charge: "", chargeIntent: "", reason: "")
        let creation = try? await RefundsAPI.createRefund(request: request)
        XCTAssertNil(creation)
        
        let refund = FrameObjects.Refund(id: "1", amountRefunded: 100, object: "", created: 0, updated: 0)
        
        do {
            session.data = try JSONEncoder().encode(refund)
            let creationTwo = try await RefundsAPI.createRefund(request: request)
            XCTAssertNotNil(creationTwo)
            XCTAssertEqual(creationTwo?.amountRefunded, refund.amountRefunded)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetRefunds() async {
        FrameNetworking.shared.asyncURLSession = session
        let refundResponse = try? await RefundsAPI.getRefunds(chargeId: "", chargeIntentId: "")
        XCTAssertNil(refundResponse)
        
        let refundResponseTwo = try? await RefundsAPI.getRefunds(chargeId: "1", chargeIntentId: "2")
        XCTAssertNil(refundResponseTwo)
        
        let refund = FrameObjects.Refund(id: "1", amountRefunded: 100, object: "", created: 0, updated: 0)
        let refundTwo = FrameObjects.Refund(id: "2", amountRefunded: 1000, object: "", created: 0, updated: 0)
        
        do {
            session.data = try JSONEncoder().encode(RefundResponses.ListRefundsResponse(meta: nil, data: [refund, refundTwo]))
            let refunds = try await RefundsAPI.getRefunds(chargeId: "1", chargeIntentId: "2")
            XCTAssertNotNil(refunds)
            XCTAssertEqual(refunds?[0].amountRefunded, refund.amountRefunded)
            XCTAssertEqual(refunds?[1].amountRefunded, refundTwo.amountRefunded)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetRefund() async {
        FrameNetworking.shared.asyncURLSession = session
        let refundResponse = try? await RefundsAPI.getRefundWith(refundId: "")
        XCTAssertNil(refundResponse)
        
        let refundResponseTwo = try? await RefundsAPI.getRefundWith(refundId: "123")
        XCTAssertNil(refundResponseTwo)
        
        let refund = FrameObjects.Refund(id: "1234", amountRefunded: 100, object: "", created: 0, updated: 0)
        
        do {
            session.data = try JSONEncoder().encode(refund)
            let refundThree = try await RefundsAPI.getRefundWith(refundId: "1234")
            XCTAssertNotNil(refundThree)
            XCTAssertEqual(refundThree?.amountRefunded, refund.amountRefunded)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCancelRefund() async {
        FrameNetworking.shared.asyncURLSession = session
        let cancellation = try? await RefundsAPI.cancelRefund(refundId: "")
        XCTAssertNil(cancellation)
        
        let cancellationTwo = try? await RefundsAPI.cancelRefund(refundId: "123")
        XCTAssertNil(cancellationTwo)
        
        let refund = FrameObjects.Refund(id: "1234", amountRefunded: 100, object: "", created: 0, updated: 0)
        
        do {
            session.data = try JSONEncoder().encode(refund)
            let cancellationThree = try await RefundsAPI.cancelRefund(refundId: "1234")
            XCTAssertNotNil(cancellationThree)
            XCTAssertEqual(cancellationThree?.amountRefunded, refund.amountRefunded)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
