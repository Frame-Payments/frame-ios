//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

// https://docs.framepayments.com/api/subscription_phases

// Protocol for Mock Testing
protocol SubscriptionPhasesProtocol {
    //async/await
    static func listAllSubscriptionPhases(subscriptionId: String) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?)
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?)
    
    // completionHandlers
    static func listAllSubscriptionPhases(subscriptionId: String, completionHandler: @escaping @Sendable (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) -> Void)
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) -> Void)
}

// Subscription Phases API
public class SubscriptionPhasesAPI: SubscriptionPhasesProtocol, @unchecked Sendable {
    // async/await
    public static func listAllSubscriptionPhases(subscriptionId: String) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) {
        guard subscriptionId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getAllSubscriptionPhases(subscriptionId: subscriptionId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard subscriptionId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard subscriptionId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.createSubscriptionPhase(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard subscriptionId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.updateSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard subscriptionId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.deleteSubscriptionPhase(subscriptionId: subscriptionId, phaseId: phaseId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase) async throws -> (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) {
        guard subscriptionId != "" else { return (nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.bulkUpdateSubscriptionPhases(subscriptionId: subscriptionId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    // completionHandlers
    public static func listAllSubscriptionPhases(subscriptionId: String, completionHandler: @escaping @Sendable (SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?, NetworkingError?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getAllSubscriptionPhases(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.getSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.createSubscriptionPhase(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.updateSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.deleteSubscriptionPhase(subscriptionId: subscriptionId, phaseId: phaseId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?, NetworkingError?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil, nil) }
        let endpoint = SubscriptionPhaseEndpoints.bulkUpdateSubscriptionPhases(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
