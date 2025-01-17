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
    static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> FrameObjects.Subscription?
    static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> FrameObjects.Subscription?
    static func getSubscriptions(page: Int?, perPage: Int?) async throws -> [FrameObjects.Subscription]?
    static func getSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription?
    static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> [FrameObjects.Subscription]?
    static func cancelSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription?
    
    //MARK: Methods using completionHandler
    static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    static func getSubscriptions(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void)
    static func getSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
    static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void)
    static func cancelSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void)
}

// Subscriptions API
public class SubscriptionsAPI: SubscriptionsProtocol, @unchecked Sendable {
    //MARK: Methods using async/await
    public static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> FrameObjects.Subscription? {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> FrameObjects.Subscription? {
        guard !subscriptionId.isEmpty else { return nil }
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func getSubscriptions(page: Int? = nil, perPage: Int? = nil) async throws -> [FrameObjects.Subscription]? {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public static func getSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription? {
        guard !subscriptionId.isEmpty else { return nil }
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> [FrameObjects.Subscription]? {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public static func cancelSubscription(subscriptionId: String) async throws -> FrameObjects.Subscription? {
        guard !subscriptionId.isEmpty else { return nil }
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    //MARK: Methods using completion handler
    public static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
            
            completionHandler(nil)
        }
    }
    
    public static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
            
            completionHandler(nil)
        }
    }
    
    public static func getSubscriptions(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            } else {
                completionHandler(nil)
            }
            
            completionHandler(nil)
        }
    }
    
    public static func getSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
            
            completionHandler(nil)
        }
    }
    
    public static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?) -> Void) {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            } else {
                completionHandler(nil)
            }
            
            completionHandler(nil)
        }
    }
    
    public static func cancelSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?) -> Void) {
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
            
            completionHandler(nil)
        }
    }
}
