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
    static func listAllSubscriptionPhases(subscriptionId: String) async throws -> SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> FrameObjects.SubscriptionPhase?
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase) async throws -> FrameObjects.SubscriptionPhase?
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase) async throws -> FrameObjects.SubscriptionPhase?
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> FrameObjects.SubscriptionPhase?
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase) async throws -> SubscriptionPhasesResponses.ListSubscriptionPhasesResponse?
    
    // completionHandlers
    static func listAllSubscriptionPhases(subscriptionId: String, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?) -> Void)
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void)
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void)
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void)
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void)
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?) -> Void)
}

// Subscription Phases API
public class SubscriptionPhasesAPI: SubscriptionPhasesProtocol, @unchecked Sendable {
    // async/await
    static func listAllSubscriptionPhases(subscriptionId: String) async throws -> SubscriptionPhasesResponses.ListSubscriptionPhasesResponse? {
        guard subscriptionId != "" else { return nil }
        let endpoint = SubscriptionPhaseEndpoints.getAllSubscriptionPhases(subscriptionId: subscriptionId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> FrameObjects.SubscriptionPhase? {
        guard subscriptionId != "" && phaseId != "" else { return nil }
        let endpoint = SubscriptionPhaseEndpoints.getSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase) async throws -> FrameObjects.SubscriptionPhase? {
        guard subscriptionId != "" else { return nil }
        let endpoint = SubscriptionPhaseEndpoints.createSubscriptionPhase(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase) async throws -> FrameObjects.SubscriptionPhase? {
        guard subscriptionId != "" && phaseId != "" else { return nil }
        let endpoint = SubscriptionPhaseEndpoints.updateSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String) async throws -> FrameObjects.SubscriptionPhase? {
        guard subscriptionId != "" && phaseId != "" else { return nil }
        let endpoint = SubscriptionPhaseEndpoints.deleteSubscriptionPhase(subscriptionId: subscriptionId, phaseId: phaseId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase) async throws -> SubscriptionPhasesResponses.ListSubscriptionPhasesResponse? {
        guard subscriptionId != "" else { return nil }
        let endpoint = SubscriptionPhaseEndpoints.bulkUpdateSubscriptionPhases(subscriptionId: subscriptionId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(SubscriptionPhasesResponses.ListSubscriptionPhasesResponse.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    // completionHandlers
    static func listAllSubscriptionPhases(subscriptionId: String, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil) }
        let endpoint = SubscriptionPhaseEndpoints.getAllSubscriptionPhases(subscriptionId: subscriptionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    static func getSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil) }
        let endpoint = SubscriptionPhaseEndpoints.getSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    static func createSubscriptionPhase(subscriptionId: String, request: SubscriptionPhaseRequests.CreateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil) }
        let endpoint = SubscriptionPhaseEndpoints.createSubscriptionPhase(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    static func updateSubscriptionPhase(subscriptionId: String, phaseId: String, request: SubscriptionPhaseRequests.UpdateSubscriptionPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil) }
        let endpoint = SubscriptionPhaseEndpoints.updateSubscriptionPhaseWith(subscriptionId: subscriptionId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    static func deleteSubscriptionPhase(subscriptionId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?) -> Void) {
        guard subscriptionId != "", phaseId != "" else { return completionHandler(nil) }
        let endpoint = SubscriptionPhaseEndpoints.deleteSubscriptionPhase(subscriptionId: subscriptionId, phaseId: phaseId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    static func bulkUpdateSubscriptionPhases(subscriptionId: String, request: SubscriptionPhaseRequests.BulkUpdateScriptionPhase, completionHandler: @escaping @Sendable (SubscriptionResponses.ListSubscriptionsResponse?) -> Void) {
        guard subscriptionId != "" else { return completionHandler(nil) }
        let endpoint = SubscriptionPhaseEndpoints.bulkUpdateSubscriptionPhases(subscriptionId: subscriptionId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SubscriptionResponses.ListSubscriptionsResponse.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
}
