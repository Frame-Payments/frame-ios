//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Objects on 8/21/25.
//

import Foundation
import XCTest
@testable import Frame_iOS

final class SubscriptionPhasesAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/subscriptions/1/phases")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    var mockPhase = FrameObjects.SubscriptionPhase(id: "phase_123",
                                                   ordinal: 1,
                                                   name: "",
                                                   pricingType: .relative,
                                                   durationType: .finite,
                                                   amount: 100,
                                                   currency: "usd",
                                                   discountPercentage: 0.3,
                                                   periodCount: 2,
                                                   interval: "",
                                                   intervalCount: 2,
                                                   livemode: false,
                                                   created: 0,
                                                   updated: 0,
                                                   object: nil)
    
    func testCreateSubscriptionPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = SubscriptionPhaseRequests.CreateSubscriptionPhase(ordinal: 1,
                                                                        pricingType: .relative,
                                                                        durationType: .finite,
                                                                        name: "",
                                                                        amountCents: 100,
                                                                        discountPercentage: 0.3,
                                                                        periodCount: 2,
                                                                        interval: "",
                                                                        intervalCount: 2)
        let createdSubscriptionPhase = try? await SubscriptionPhasesAPI.createSubscriptionPhase(subscriptionId: "", request: request).0
        XCTAssertNil(createdSubscriptionPhase)
        
        do {
            session.data = try JSONEncoder().encode(mockPhase)
            let (createdSecondSubscription, error) = try await SubscriptionPhasesAPI.createSubscriptionPhase(subscriptionId: "sub_123", request: request)
            XCTAssertNotNil(createdSecondSubscription)
            XCTAssertEqual(createdSecondSubscription?.pricingType, .relative)
            XCTAssertEqual(createdSecondSubscription?.durationType, .finite)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateSubscriptionPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = SubscriptionPhaseRequests.UpdateSubscriptionPhase(ordinal: nil,
                                                                        pricingType: .staticType,
                                                                        durationType: nil,
                                                                        name: nil,
                                                                        amountCents: nil,
                                                                        discountPercentage: nil,
                                                                        periodCount: nil,
                                                                        interval: nil,
                                                                        intervalCount: nil)
        
        let updatedSubscriptionPhase = try? await SubscriptionPhasesAPI.updateSubscriptionPhase(subscriptionId: "", phaseId: "phase_123", request: request).0
        XCTAssertNil(updatedSubscriptionPhase)
        
        let secondUpdatedSubscriptionPhase = try? await SubscriptionPhasesAPI.updateSubscriptionPhase(subscriptionId: "sub_123", phaseId: "", request: request).0
        XCTAssertNil(secondUpdatedSubscriptionPhase)
        
        mockPhase.pricingType = .staticType
        do {
            session.data = try JSONEncoder().encode(mockPhase)
            let (thirdUpdatedSubscription, error) = try await SubscriptionPhasesAPI.updateSubscriptionPhase(subscriptionId: "sub_123", phaseId: "phase_123", request: request)
            XCTAssertNotNil(thirdUpdatedSubscription)
            XCTAssertEqual(thirdUpdatedSubscription?.pricingType, .staticType)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetSubscriptionPhases() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let subscriptionPhase = try? await SubscriptionPhasesAPI.listAllSubscriptionPhases(subscriptionId: "").0
        XCTAssertNil(subscriptionPhase)
        
        let meta = SubscriptionPhasesResponses.SubscriptionPhaseMeta(subscriptionId: "sub_12345")
        let listResponse = SubscriptionPhasesResponses.ListSubscriptionPhasesResponse(meta: meta, phases: [mockPhase])
        
        do {
            session.data = try JSONEncoder().encode(listResponse)
            let (secondSubscriptionPhase, error) = try await SubscriptionPhasesAPI.listAllSubscriptionPhases(subscriptionId: "sub_123")
            XCTAssertNotNil(secondSubscriptionPhase)
            XCTAssertEqual(secondSubscriptionPhase?.phases?.first?.id, "phase_123")
            XCTAssertEqual(secondSubscriptionPhase?.meta?.subscriptionId, "sub_12345")
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetSubscriptionPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let subscriptionPhase = try? await SubscriptionPhasesAPI.getSubscriptionPhase(subscriptionId: "", phaseId: "phase_123").0
        XCTAssertNil(subscriptionPhase)
        
        let secondSubscriptionPhase = try? await SubscriptionPhasesAPI.getSubscriptionPhase(subscriptionId: "sub_123", phaseId: "").0
        XCTAssertNil(secondSubscriptionPhase)
        
        do {
            session.data = try JSONEncoder().encode(mockPhase)
            let (thirdUpdatedSubscriptionPhase, error) = try await SubscriptionPhasesAPI.getSubscriptionPhase(subscriptionId: "sub_123", phaseId: "phase_123")
            XCTAssertNotNil(thirdUpdatedSubscriptionPhase)
            XCTAssertEqual(thirdUpdatedSubscriptionPhase?.pricingType, .relative)
            XCTAssertEqual(thirdUpdatedSubscriptionPhase?.amount, 100)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    
    func testDeleteSubscriptionPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let subscriptionPhase = try? await SubscriptionPhasesAPI.deleteSubscriptionPhase(subscriptionId: "", phaseId: "phase_123").0
        XCTAssertNil(subscriptionPhase)
        
        let secondSubscriptionPhase = try? await SubscriptionPhasesAPI.deleteSubscriptionPhase(subscriptionId: "sub_123", phaseId: "").0
        XCTAssertNil(secondSubscriptionPhase)
        
        do {
            session.data = try JSONEncoder().encode(mockPhase)
            let (thirdUpdatedSubscriptionPhase, error) = try await SubscriptionPhasesAPI.deleteSubscriptionPhase(subscriptionId: "sub_123", phaseId: "phase_123")
            XCTAssertNotNil(thirdUpdatedSubscriptionPhase)
            XCTAssertEqual(thirdUpdatedSubscriptionPhase?.pricingType, .relative)
            XCTAssertEqual(thirdUpdatedSubscriptionPhase?.amount, 100)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
