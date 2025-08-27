//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/8/24.
//

import XCTest
@testable import Frame_iOS

final class SubscriptionsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/subscriptions")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    
    func testCreateSubscription() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = SubscriptionRequest.CreateSubscriptionRequest(customer: "1", product: "2", currency: "USD", defaultPaymentMethod: "1")
        let createdSubscription = try? await SubscriptionsAPI.createSubscription(request: request).0
        XCTAssertNil(createdSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let (createdSecondSubscription, error) = try await SubscriptionsAPI.createSubscription(request: request)
            XCTAssertNotNil(createdSecondSubscription)
            XCTAssertEqual(createdSecondSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateSubscription() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = SubscriptionRequest.UpdateSubscriptionRequest(description: "Testing", defaultPaymentMethod: "1")
        let updatedSubscription = try? await SubscriptionsAPI.updateSubscription(subscriptionId: "", request: request).0
        XCTAssertNil(updatedSubscription)
        
        let secondUpdatedSubscription = try? await SubscriptionsAPI.updateSubscription(subscriptionId: "123", request: request).0
        XCTAssertNil(secondUpdatedSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let (thirdUpdatedSubscription, error) = try await SubscriptionsAPI.updateSubscription(subscriptionId: "1234", request: request)
            XCTAssertNotNil(thirdUpdatedSubscription)
            XCTAssertEqual(thirdUpdatedSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetSubscriptions() async {
        FrameNetworking.shared.asyncURLSession = session
        let receivedSubscriptions = try? await SubscriptionsAPI.getSubscriptions().0
        XCTAssertNil(receivedSubscriptions)
        
        let firstSubscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        let secondSubscription = FrameObjects.Subscription(id: "2", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: true,
                                                     currency: "CAD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(SubscriptionResponses.ListSubscriptionsResponse(meta: nil, data: [firstSubscription, secondSubscription]))
            let (secondReceivedSubscriptions, error) = try await SubscriptionsAPI.getSubscriptions()
            XCTAssertNotNil(secondReceivedSubscriptions)
            XCTAssertEqual(secondReceivedSubscriptions?.data?[0].currency, firstSubscription.currency)
            XCTAssertEqual(secondReceivedSubscriptions?.data?[1].currency, secondSubscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetSubscription() async {

        FrameNetworking.shared.asyncURLSession = session
        let receivedSubscription = try? await SubscriptionsAPI.getSubscription(subscriptionId: "").0
        XCTAssertNil(receivedSubscription)
        
        let secondReceivedSubscription = try? await SubscriptionsAPI.getSubscription(subscriptionId: "123").0
        XCTAssertNil(secondReceivedSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let (thirdReceivedSubscription, error) = try await SubscriptionsAPI.getSubscription(subscriptionId: "1234")
            XCTAssertNotNil(thirdReceivedSubscription)
            XCTAssertEqual(thirdReceivedSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testSearchSubscriptions() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = SubscriptionRequest.SearchSubscriptionRequest(status: "updated")
        let searchedSubscriptions = try? await SubscriptionsAPI.searchSubscription(request: request).0
        XCTAssertNil(searchedSubscriptions)
        
        let firstSubscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        let secondSubscription = FrameObjects.Subscription(id: "2", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: true,
                                                     currency: "CAD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(SubscriptionResponses.ListSubscriptionsResponse(meta: nil, data: [firstSubscription, secondSubscription]))
            let (secondSearch, error) = try await SubscriptionsAPI.searchSubscription(request: request)
            XCTAssertNotNil(secondSearch)
            XCTAssertEqual(secondSearch?[0].currency, firstSubscription.currency)
            XCTAssertEqual(secondSearch?[1].currency, secondSubscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCancelSubscription() async {
        FrameNetworking.shared.asyncURLSession = session
        let cancelledSubscription = try? await SubscriptionsAPI.cancelSubscription(subscriptionId: "").0
        XCTAssertNil(cancelledSubscription)
        
        let secondCancelledSubscription = try? await SubscriptionsAPI.cancelSubscription(subscriptionId: "123").0
        XCTAssertNil(secondCancelledSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let (thirdCancelledSubscription, error) = try await SubscriptionsAPI.getSubscription(subscriptionId: "1234")
            XCTAssertNotNil(thirdCancelledSubscription)
            XCTAssertEqual(thirdCancelledSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
