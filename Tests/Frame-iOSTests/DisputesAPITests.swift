//
//  DisputesAPITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import XCTest
@testable import Frame

final class DisputesAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/disputes")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    var disputeResponse = FrameObjects.Dispute(id: "disp_1", amount: 1000,
                                               currency: "usd", reason: .bankCannotProcess,
                                               status: .needsResponse, object: "dispute",
                                               livemode: true, created: 0, updated: 0)
    
    func testUpdateDispute() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let evidence = FrameObjects.DisputeEvidence(evidenceCustomerEmailAddress: "test@gmail.com")
        let request = DisputeRequests.UpdateDisputeRequest(evidence: evidence, submit: true)
        XCTAssertNotNil(request.evidence)
        
        let updatedDispute = try? await DisputesAPI.updateDispute(disputeId: "disp_1", request: request).0
        XCTAssertNil(updatedDispute)
        
        disputeResponse.evidence = evidence
        
        do {
            session.data = try JSONEncoder().encode(disputeResponse)
            let (updatedDisputeTwo, _) = try await DisputesAPI.updateDispute(disputeId: "disp_1", request: request)
            XCTAssertNotNil(updatedDisputeTwo)
            XCTAssertEqual(updatedDisputeTwo?.evidence, disputeResponse.evidence)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetDisputes() async {
        FrameNetworking.shared.asyncURLSession = session
        let dispute = try? await DisputesAPI.getDisputes(chargeId: "", chargeIntentId: "").0
        XCTAssertNil(dispute)
        
        let disputeResponseTwo = try? await DisputesAPI.getDisputes(chargeId: "1", chargeIntentId: "2").0
        XCTAssertNil(disputeResponseTwo)
        
        do {
            session.data = try JSONEncoder().encode(DisputeResponses.ListDisputesResponse(data: [disputeResponse]))
            let (disputes, _) = try await DisputesAPI.getDisputes(chargeId: "1", chargeIntentId: "2")
            XCTAssertNotNil(disputes)
            XCTAssertEqual(disputes?.data?[0].amount, disputeResponse.amount)
            XCTAssertEqual(disputes?.data?[0].object, disputeResponse.object)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetDispute() async {
        FrameNetworking.shared.asyncURLSession = session
        let dispute = try? await DisputesAPI.getDispute(disputeId: "disp_1").0
        XCTAssertNil(dispute)
        
        do {
            session.data = try JSONEncoder().encode(disputeResponse)
            let (disputeTwo, _) = try await DisputesAPI.getDispute(disputeId: "disp_1")
            XCTAssertNotNil(disputeTwo)
            XCTAssertEqual(disputeTwo?.currency, disputeResponse.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCloseDispute() async {
        FrameNetworking.shared.asyncURLSession = session
        let cancellation = try? await DisputesAPI.closeDispute(disputeId: "disp_1").0
        XCTAssertNil(cancellation)
        
        let cancellationTwo = try? await DisputesAPI.closeDispute(disputeId: "disp_1").0
        XCTAssertNil(cancellationTwo)
        
        do {
            session.data = try JSONEncoder().encode(disputeResponse)
            let (cancellationThree, _) = try await DisputesAPI.closeDispute(disputeId: "disp_1")
            XCTAssertNotNil(cancellationThree)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
