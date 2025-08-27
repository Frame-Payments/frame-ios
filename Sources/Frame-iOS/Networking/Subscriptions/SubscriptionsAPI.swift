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
    static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> (FrameObjects.Subscription?, NetworkingError?)
    static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> (FrameObjects.Subscription?, NetworkingError?)
    static func getSubscriptions(page: Int?, perPage: Int?) async throws -> (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?)
    static func getSubscription(subscriptionId: String) async throws -> (FrameObjects.Subscription?, NetworkingError?)
    static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> ([FrameObjects.Subscription]?, NetworkingError?)
    static func cancelSubscription(subscriptionId: String) async throws -> (FrameObjects.Subscription?, NetworkingError?)
    
    //MARK: Methods using completionHandler
    static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void)
    static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void)
    static func getSubscriptions(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) -> Void)
    static func getSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void)
    static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?, NetworkingError?) -> Void)
    static func cancelSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void)
}

// Subscriptions API
public class SubscriptionsAPI: SubscriptionsProtocol, @unchecked Sendable {
    //MARK: Methods using async/await
    public static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        guard !subscriptionId.isEmpty else { return (nil, nil) }
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getSubscriptions(page: Int? = nil, perPage: Int? = nil) async throws -> (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getSubscription(subscriptionId: String) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        guard !subscriptionId.isEmpty else { return (nil, nil) }
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> ([FrameObjects.Subscription]?, NetworkingError?) {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return (decodedResponse.data, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func cancelSubscription(subscriptionId: String) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        guard !subscriptionId.isEmpty else { return (nil, nil) }
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //MARK: Methods using completion handler
    public static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getSubscriptions(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func cancelSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
