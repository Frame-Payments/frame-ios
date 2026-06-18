//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

// https://docs.framepayments.com/api/subscription_phases

/// Internal contract defining the async/await and completion-handler surface for the Subscription Phases resource.
protocol SubscriptionPhasesProtocol {
    //async/await

    /// Lists all phases belonging to a subscription.
    /// - Parameter subscriptionId: The unique identifier of the parent subscription.
    /// - Returns: A paginated list response and an optional networking error.
    static func listAllSubscriptionPhases(subscriptionId: String) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?)

    /// Retrieves a single subscription phase by its identifier.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to fetch.
    /// - Returns: The matching ``FrameObjects/SubscriptionPhase`` and an optional networking error.
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)

    /// Creates a new phase on an existing subscription.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The creation parameters wrapped in a ``SubscriptionPhaseRequests/CreateSubscriptionPhase`` body.
    /// - Returns: The newly created ``FrameObjects/SubscriptionPhase`` and an optional networking error.
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)

    /// Updates an existing subscription phase.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to update.
    ///   - request: The update parameters wrapped in a ``SubscriptionPhaseRequests/UpdateSubscriptionPhase`` body.
    /// - Returns: The updated ``FrameObjects/SubscriptionPhase`` and an optional networking error.
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)

    /// Deletes a subscription phase.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to delete.
    /// - Returns: An optional networking error if the deletion failed.
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (NetworkingError?)

    /// Replaces all phases on a subscription in a single atomic operation.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The bulk-update parameters wrapped in a ``SubscriptionPhaseRequests/BulkUpdateScriptionPhase`` body.
    /// - Returns: The updated list of phases and an optional networking error.
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?)

    // completionHandlers

    /// Completion-handler variant of ``listAllSubscriptionPhasesAsync(_:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - completionHandler: Called with the paginated list response and an optional networking error.
    static func listAllSubscriptionPhases(subscriptionId: String, completionHandler: @escaping @Sendable (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) -> Void)

    /// Completion-handler variant of ``getSubscriptionPhaseAsync(_:phaseId:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to fetch.
    ///   - completionHandler: Called with the matching phase and an optional networking error.
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)

    /// Completion-handler variant of ``createSubscriptionPhaseAsync(_:request:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The creation parameters.
    ///   - completionHandler: Called with the newly created phase and an optional networking error.
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)

    /// Completion-handler variant of ``updateSubscriptionPhaseAsync(_:phaseId:request:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to update.
    ///   - request: The update parameters.
    ///   - completionHandler: Called with the updated phase and an optional networking error.
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)

    /// Completion-handler variant of ``deleteSubscriptionPhaseAsync(_:phaseId:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to delete.
    ///   - completionHandler: Called with an optional networking error.
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (NetworkingError?) -> Void)

    /// Completion-handler variant of ``bulkUpdateSubscriptionPhasesAsync(_:request:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The bulk-update parameters.
    ///   - completionHandler: Called with the updated subscriptions list response and an optional networking error.
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) -> Void)
}

/// Manages the Subscription Phases resource of the Frame Payments API.
///
/// Use `SubscriptionPhasesAPI` to list, retrieve, create, update, delete, and bulk-update
/// phases that belong to a subscription. Each method is available in both async/await and
/// completion-handler forms.
public class SubscriptionPhasesAPI: SubscriptionPhasesProtocol, @unchecked Sendable {
    // async/await

    /// Lists all phases for the given subscription.
    /// - Parameter subscriptionId: The unique identifier of the parent subscription.
    /// - Returns: A paginated list of subscription phases and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func listAllSubscriptionPhases(subscriptionId: String) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) {
        guard subscriptionId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getAllSubscriptionPhases(subscriptionId: subscriptionId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Fetches a single subscription phase by its identifier.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to retrieve.
    /// - Returns: The requested ``FrameObjects/SubscriptionPhase`` and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard subscriptionId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Creates a new phase on an existing subscription.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The creation parameters.
    /// - Returns: The newly created ``FrameObjects/SubscriptionPhase`` and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard subscriptionId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.createSubscriptionPhase(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Updates an existing subscription phase.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to update.
    ///   - request: The update parameters.
    /// - Returns: The updated ``FrameObjects/SubscriptionPhase`` and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard subscriptionId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.updateSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Deletes a subscription phase.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to delete.
    /// - Returns: An optional networking error if the deletion failed.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (NetworkingError?) {
        guard subscriptionId != "" && phaseId != "" else { return (nil) }
        let endpoint = SubscriptionPhaseEndpoints.deleteSubscriptionPhase(subscriptionId: subscriptionId, phaseId: phaseId)

        let (_, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        return error
    }

    /// Replaces all phases on a subscription in a single atomic operation.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The bulk-update parameters.
    /// - Returns: The updated list of phases and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) {
        guard subscriptionId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.bulkUpdateSubscriptionPhases(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // completionHandlers

    /// Completion-handler variant of ``listAllSubscriptionPhases(subscriptionId:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - completionHandler: Called with the paginated list response and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func listAllSubscriptionPhases(subscriptionId: String, completionHandler: @escaping @Sendable (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getAllSubscriptionPhases(subscriptionId: subscriptionId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getSubscriptionPhase(subscriptionId:phaseId:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to fetch.
    ///   - completionHandler: Called with the matching phase and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``createSubscriptionPhase(subscriptionId:request:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The creation parameters.
    ///   - completionHandler: Called with the newly created phase and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.createSubscriptionPhase(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``updateSubscriptionPhase(subscriptionId:phaseId:request:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to update.
    ///   - request: The update parameters.
    ///   - completionHandler: Called with the updated phase and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.updateSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``deleteSubscriptionPhase(subscriptionId:phaseId:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - phaseId: The unique identifier of the phase to delete.
    ///   - completionHandler: Called with an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (NetworkingError?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil) }
        let endpoint = SubscriptionPhaseEndpoints.deleteSubscriptionPhase(subscriptionId: subscriptionId, phaseId: phaseId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            completionHandler(error)
        }
    }

    /// Completion-handler variant of ``bulkUpdateSubscriptionPhases(subscriptionId:request:)``.
    /// - Parameters:
    ///   - subscriptionId: The unique identifier of the parent subscription.
    ///   - request: The bulk-update parameters.
    ///   - completionHandler: Called with the updated subscriptions list response and an optional networking error.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.bulkUpdateSubscriptionPhases(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
