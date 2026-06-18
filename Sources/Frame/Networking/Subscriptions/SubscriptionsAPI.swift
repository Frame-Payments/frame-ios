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

/// Manages subscription resources in the Frame Payments SDK.
///
/// `SubscriptionsAPI` provides static methods for creating, retrieving, updating,
/// searching, and cancelling recurring subscriptions via the Frame Payments API.
/// Each operation is available as both an `async`/`await` variant and a
/// completion-handler variant for compatibility with callback-based code.
public class SubscriptionsAPI: SubscriptionsProtocol, @unchecked Sendable {
    //MARK: Methods using async/await

    /// Creates a new subscription.
    ///
    /// - Parameter request: The request body containing subscription creation parameters.
    /// - Returns: A tuple of the created ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Updates an existing subscription.
    ///
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the subscription to update.
    ///   - request: The request body containing fields to update.
    /// - Returns: A tuple of the updated ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        guard !subscriptionId.isEmpty else { return (nil, nil) }
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a paginated list of subscriptions.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve. Pass `nil` to use the API default.
    ///   - perPage: The number of results per page. Pass `nil` to use the API default.
    /// - Returns: A tuple of the ``SubscriptionResponses/ListSubscriptionsResponse`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getSubscriptions(page: Int? = nil, perPage: Int? = nil) async throws -> (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single subscription by its identifier.
    ///
    /// - Parameter subscriptionId: The unique identifier of the subscription.
    /// - Returns: A tuple of the matching ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getSubscription(subscriptionId: String) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        guard !subscriptionId.isEmpty else { return (nil, nil) }
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Searches for subscriptions matching the given criteria.
    ///
    /// - Parameter request: The request body containing search filters.
    /// - Returns: A tuple of matching ``FrameObjects/Subscription`` objects and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?) async throws -> ([FrameObjects.Subscription]?, NetworkingError?) {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
            return (decodedResponse.data, error)
        } else {
            return (nil, error)
        }
    }

    /// Cancels an active subscription.
    ///
    /// - Parameter subscriptionId: The unique identifier of the subscription to cancel.
    /// - Returns: A tuple of the cancelled ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func cancelSubscription(subscriptionId: String) async throws -> (FrameObjects.Subscription?, NetworkingError?) {
        guard !subscriptionId.isEmpty else { return (nil, nil) }
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //MARK: Methods using completion handler

    /// Completion-handler variant of ``createSubscription(request:)``.
    ///
    /// - Parameters:
    ///   - request: The request body containing subscription creation parameters.
    ///   - completionHandler: Called with the created ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createSubscription(request: SubscriptionRequest.CreateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.createSubscription
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``updateSubscription(subscriptionId:request:)``.
    ///
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the subscription to update.
    ///   - request: The request body containing fields to update.
    ///   - completionHandler: Called with the updated ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateSubscription(subscriptionId: String, request: SubscriptionRequest.UpdateSubscriptionRequest?, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.updateSubscription(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getSubscriptions(page:perPage:)``.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve. Pass `nil` to use the API default.
    ///   - perPage: The number of results per page. Pass `nil` to use the API default.
    ///   - completionHandler: Called with the ``SubscriptionResponses/ListSubscriptionsResponse`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getSubscriptions(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscriptions(perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getSubscription(subscriptionId:)``.
    ///
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the subscription.
    ///   - completionHandler: Called with the matching ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.getSubscription(subscriptionId: subscriptionId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``searchSubscription(request:)``.
    ///
    /// - Parameters:
    ///   - request: The request body containing search filters.
    ///   - completionHandler: Called with matching ``FrameObjects/Subscription`` objects and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func searchSubscription(request: SubscriptionRequest.SearchSubscriptionRequest?, completionHandler: @escaping @Sendable ([FrameObjects.Subscription]?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.searchSubscriptions
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse.data, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``cancelSubscription(subscriptionId:)``.
    ///
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the subscription to cancel.
    ///   - completionHandler: Called with the cancelled ``FrameObjects/Subscription`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func cancelSubscription(subscriptionId: String, completionHandler: @escaping @Sendable (FrameObjects.Subscription?, NetworkingError?) -> Void) {
        let endpoint = SubscriptionEndpoints.cancelSubscription(subscriptionId: subscriptionId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Subscription.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
