//
//  SubscriptionsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

import Foundation

// https://docs.framepayments.com/subscriptions#search-subscriptions

// Protocol for Mock Testing
protocol SubscriptionsProtocol {
    //MARK: Methods using async/await
    func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> FrameObjects.Subscription?
    func updateSubscription(id: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> FrameObjects.Subscription?
    func getSubscriptions() async throws -> [FrameObjects.Subscription]?
    func getSubscription(id: String) async throws -> FrameObjects.Subscription?
    func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> [FrameObjects.Subscription]?
    func cancelSubscription(id: String) async throws -> FrameObjects.Subscription?
    
    //MARK: Methods using completionHandler
    func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    func updateSubscription(id: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    func getSubscriptions(completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void)
    func getSubscription(id: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void)
    func cancelSubscription(id: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
}

// Payments Methods API
public class SubscriptionsAPI: SubscriptionsProtocol {
    public init() {}
    
    //MARK: Methods using async/await
    public func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> FrameObjects.Subscription? {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updateSubscription(id: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> FrameObjects.Subscription? {
        let endpoint = SubscriptionEndpoints.updateSubscription(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getSubscriptions() async throws -> [FrameObjects.Subscription]? {
        let endpoint = SubscriptionEndpoints.getSubscriptions
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getSubscription(id: String) async throws -> FrameObjects.Subscription? {
        let endpoint = SubscriptionEndpoints.getSubscription(id: id)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> [FrameObjects.Subscription]? {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func cancelSubscription(id: String) async throws -> FrameObjects.Subscription? {
        let endpoint = SubscriptionEndpoints.cancelSubscription(id: id)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    //MARK: Methods using completion handler
    public func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updateSubscription(id: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.updateSubscription(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getSubscriptions(completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscriptions
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public  func getSubscription(id: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscription(id: id)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void) {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func cancelSubscription(id: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.cancelSubscription(id: id)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
