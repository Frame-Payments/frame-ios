//
//  SubscriptionsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

import Foundation

// https://docs.framepayments.com/subscriptions

// Protocol for Mock Testing
protocol SubscriptionsProtocol {
    //MARK: Methods using async/await
    func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> FrameObjects.Subscription?
    func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> FrameObjects.Subscription?
    func getSubscriptions(page: Int?, perPage: Int?) async throws -> [FrameObjects.Subscription]?
    func getSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription?
    func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> [FrameObjects.Subscription]?
    func cancelSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription?
    
    //MARK: Methods using completionHandler
    func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    func getSubscriptions(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void)
    func getSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void)
    func cancelSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
}

// Subscriptions API
public class SubscriptionsAPI: SubscriptionsProtocol, @unchecked Sendable {
    public init(mockSession: URLSessionProtocol? = nil) {
        self.urlSession = mockSession ?? URLSession.shared
    }
    
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    let urlSession: URLSessionProtocol
    
    //MARK: Methods using async/await
    public func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> FrameObjects.Subscription? {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(urlSession: urlSession, endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> FrameObjects.Subscription? {
        guard !subscriptionId.isEmpty else { return nil }
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(urlSession: urlSession, endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getSubscriptions(page: Int? = nil, perPage: Int? = nil) async throws -> [FrameObjects.Subscription]? {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(urlSession: urlSession, endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription? {
        guard !subscriptionId.isEmpty else { return nil }
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(urlSession: urlSession, endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> [FrameObjects.Subscription]? {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(urlSession: urlSession, endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func cancelSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription? {
        guard !subscriptionId.isEmpty else { return nil }
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(urlSession: urlSession, endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    //MARK: Methods using completion handler
    public func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getSubscriptions(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public  func getSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void) {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func cancelSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
