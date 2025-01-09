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
        let request = SubscriptionRequest.CreateSubscriptionRequest(customer: "1", product: "2", currency: "USD", defaultPaymentMethod: "1")
        let createdSubscription = try? await SubscriptionsAPI(mockSession: session).createSubscription(request: request)
        XCTAssertNil(createdSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let createdSecondSubscription = try await SubscriptionsAPI(mockSession: session).createSubscription(request: request)
            XCTAssertNotNil(createdSecondSubscription)
            XCTAssertEqual(createdSecondSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateSubscription() async {
        let request = SubscriptionRequest.UpdateSubscriptionRequest(description: "Testing", defaultPaymentMethod: "1")
        let updatedSubscription = try? await SubscriptionsAPI(mockSession: session).updateSubscription(subscriptionId: "", request: request)
        XCTAssertNil(updatedSubscription)
        
        let secondUpdatedSubscription = try? await SubscriptionsAPI(mockSession: session).updateSubscription(subscriptionId: "123", request: request)
        XCTAssertNil(secondUpdatedSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let thirdUpdatedSubscription = try await SubscriptionsAPI(mockSession: session).updateSubscription(subscriptionId: "1234", request: request)
            XCTAssertNotNil(thirdUpdatedSubscription)
            XCTAssertEqual(thirdUpdatedSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetSubscriptions() async {
        let receivedSubscriptions = try? await SubscriptionsAPI(mockSession: session).getSubscriptions()
        XCTAssertNil(receivedSubscriptions)
        
        let firstSubscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        let secondSubscription = FrameObjects.Subscription(id: "2", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: true,
                                                     currency: "CAD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(SubscriptionResponses.ListSubscriptionsResponse(meta: nil, data: [firstSubscription, secondSubscription]))
            let secondReceivedSubscriptions = try? await SubscriptionsAPI(mockSession: session).getSubscriptions()
            XCTAssertNotNil(secondReceivedSubscriptions)
            XCTAssertEqual(secondReceivedSubscriptions?[0].currency, firstSubscription.currency)
            XCTAssertEqual(secondReceivedSubscriptions?[1].currency, secondSubscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetSubscription() async {
        let receivedSubscription = try? await SubscriptionsAPI(mockSession: session).getSubscription(subscriptionId: "")
        XCTAssertNil(receivedSubscription)
        
        let secondReceivedSubscription = try? await SubscriptionsAPI(mockSession: session).getSubscription(subscriptionId: "123")
        XCTAssertNil(secondReceivedSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let thirdReceivedSubscription = try? await SubscriptionsAPI(mockSession: session).getSubscription(subscriptionId: "1234")
            XCTAssertNotNil(thirdReceivedSubscription)
            XCTAssertEqual(thirdReceivedSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testSearchSubscriptions() async {
        let request = SubscriptionRequest.SearchSubscriptionRequest(status: "updated")
        let searchedSubscriptions = try? await SubscriptionsAPI(mockSession: session).searchSubscription(request: request)
        XCTAssertNil(searchedSubscriptions)
        
        let firstSubscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        let secondSubscription = FrameObjects.Subscription(id: "2", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: true,
                                                     currency: "CAD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(SubscriptionResponses.ListSubscriptionsResponse(meta: nil, data: [firstSubscription, secondSubscription]))
            let secondSearch = try await SubscriptionsAPI(mockSession: session).searchSubscription(request: request)
            XCTAssertNotNil(secondSearch)
            XCTAssertEqual(secondSearch?[0].currency, firstSubscription.currency)
            XCTAssertEqual(secondSearch?[1].currency, secondSubscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testCancelSubscription() async {
        let cancelledSubscription = try? await SubscriptionsAPI(mockSession: session).cancelSubscription(subscriptionId: "")
        XCTAssertNil(cancelledSubscription)
        
        let secondCancelledSubscription = try? await SubscriptionsAPI(mockSession: session).cancelSubscription(subscriptionId: "123")
        XCTAssertNil(secondCancelledSubscription)
        
        let subscription = FrameObjects.Subscription(id: "1", description: "", currentPeriodStart: 0, currentPeriodEnd: 0, livemode: false,
                                                     currency: "USD", status: "", quantity: 1, defaultPaymentMethod: "", object: "", created: 0, startDate: 0)
        
        do {
            session.data = try JSONEncoder().encode(subscription)
            let thirdCancelledSubscription = try await SubscriptionsAPI(mockSession: session).getSubscription(subscriptionId: "1234")
            XCTAssertNotNil(thirdCancelledSubscription)
            XCTAssertEqual(thirdCancelledSubscription?.currency, subscription.currency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
