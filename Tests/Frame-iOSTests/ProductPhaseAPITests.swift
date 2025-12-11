//
//  ProductPhasesAPITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation
import XCTest
@testable import Frame_iOS

final class ProductPhasesAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/subscriptions/1/phases")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    var mockPhase = FrameObjects.SubscriptionPhase(id: "phase_123",
                                                   ordinal: 1,
                                                   name: "New Phase",
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
    
    func testCreateProductPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = ProductPhaseRequests.CreateProductPhase(ordinal: 1,
                                                            pricingType: .relative,
                                                            name: "New Phase",
                                                            amountCents: 100,
                                                            discountPercentage: 0.3,
                                                            periodCount: 2)
        let createdSubscriptionPhase = try? await ProductPhasesAPI.createProductPhase(productId: "prod_123", request: request).0
        XCTAssertNil(createdSubscriptionPhase)
        
        do {
            session.data = try JSONEncoder().encode(mockPhase)
            let (createdSecondSubscription, error) = try await ProductPhasesAPI.createProductPhase(productId: "prod_123", request: request)
            XCTAssertNotNil(createdSecondSubscription)
            XCTAssertEqual(createdSecondSubscription?.name, mockPhase.name)
            XCTAssertEqual(createdSecondSubscription?.periodCount, mockPhase.periodCount)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateProductPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = ProductPhaseRequests.UpdateProductPhase(ordinal: nil,
                                                            pricingType: .staticType,
                                                            name: nil,
                                                            amountCents: nil,
                                                            discountPercentage: nil,
                                                            periodCount: nil,)
        
        let updatedSubscriptionPhase = try? await ProductPhasesAPI.updateProductPhase(productId: "prod_123", phaseId: "phase_123", request: request).0
        XCTAssertNil(updatedSubscriptionPhase)
        
        let secondUpdatedSubscriptionPhase = try? await ProductPhasesAPI.updateProductPhase(productId: "prod_123", phaseId: "", request: request).0
        XCTAssertNil(secondUpdatedSubscriptionPhase)
        
        mockPhase.pricingType = .staticType
        
        do {
            session.data = try JSONEncoder().encode(mockPhase)
            let (thirdUpdatedSubscription, error) = try await ProductPhasesAPI.updateProductPhase(productId: "prod_123", phaseId: "phase_123", request: request)
            XCTAssertNotNil(thirdUpdatedSubscription)
            XCTAssertEqual(thirdUpdatedSubscription?.pricingType, mockPhase.pricingType)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetProductPhases() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let subscriptionPhase = try? await ProductPhasesAPI.listAllProductPhases(productId: "prod_123").0
        XCTAssertNil(subscriptionPhase)
        
        let meta = ProductPhasesResponses.ProductPhaseMeta(productId: "prod_123")
        let listResponse = ProductPhasesResponses.ListProductPhasesResponse(meta: meta, phases: [mockPhase])
        
        do {
            session.data = try JSONEncoder().encode(listResponse)
            let (secondSubscriptionPhase, error) = try await ProductPhasesAPI.listAllProductPhases(productId: "prod_123")
            XCTAssertNotNil(secondSubscriptionPhase)
            XCTAssertEqual(secondSubscriptionPhase?.phases?.first?.id, "phase_123")
            XCTAssertEqual(secondSubscriptionPhase?.meta?.productId, "prod_123")
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetProductPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let subscriptionPhase = try? await ProductPhasesAPI.getProductPhase(productId: "prod_123", phaseId: "phase_123").0
        XCTAssertNil(subscriptionPhase)
        
        let secondSubscriptionPhase = try? await ProductPhasesAPI.getProductPhase(productId: "prod_123", phaseId: "phase_123").0
        XCTAssertNil(secondSubscriptionPhase)
        
        do {
            session.data = try JSONEncoder().encode(mockPhase)
            let (thirdUpdatedSubscriptionPhase, error) = try await ProductPhasesAPI.getProductPhase(productId: "prod_123", phaseId: "phase_123")
            XCTAssertNotNil(thirdUpdatedSubscriptionPhase)
            XCTAssertEqual(thirdUpdatedSubscriptionPhase?.pricingType, mockPhase.pricingType)
            XCTAssertEqual(thirdUpdatedSubscriptionPhase?.amount, mockPhase.amount)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    
    func testDeleteProductPhase() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let phaseError = try? await ProductPhasesAPI.deleteProductPhase(productId: "prod_123", phaseId: "")
        XCTAssertNil(phaseError)
        
        let secondPhaseError = try? await ProductPhasesAPI.deleteProductPhase(productId: "", phaseId: "phase_123")
        XCTAssertNil(secondPhaseError)
    }
}
