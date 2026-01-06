//
//  DisputesAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import Foundation

// https://docs.framepayments.com/api/disputes

// Protocol for Mock Testing
protocol DisputesProtocol {
    //async/await
    static func updateDispute(disputeId: String, request: DisputeRequests.UpdateDisputeRequest) async throws -> (FrameObjects.Dispute?, NetworkingError?)
    static func getDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?)
    static func getDisputes(chargeId: String?, chargeIntentId: String?, perPage: Int, page : Int) async throws -> (DisputeResponses.ListDisputesResponse?, NetworkingError?)
    static func closeDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?)
    
    // completionHandlers
    static func updateDispute(disputeId: String,request: DisputeRequests.UpdateDisputeRequest, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void)
    static func getDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void)
    static func getDisputes(chargeId: String?, chargeIntentId: String?, perPage: Int, page : Int, completionHandler: @escaping @Sendable (DisputeResponses.ListDisputesResponse?, NetworkingError?) -> Void)
    static func closeDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void)
}

// Disputes API
public class DisputesAPI: DisputesProtocol, @unchecked Sendable {
    //async/await
    static func updateDispute(disputeId: String, request: DisputeRequests.UpdateDisputeRequest) async throws -> (FrameObjects.Dispute?, NetworkingError?) {
        let endpoint = DisputeEndpoints.updateDispute(disputeId: disputeId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func getDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?) {
        let endpoint = DisputeEndpoints.getDispute(disputeId: disputeId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func getDisputes(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int = 10, page: Int = 1) async throws -> (DisputeResponses.ListDisputesResponse?, NetworkingError?) {
        let endpoint = DisputeEndpoints.getDisputes(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(DisputeResponses.ListDisputesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func closeDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?) {
        let endpoint = DisputeEndpoints.closeDispute(disputeId: disputeId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //completionHandler
    static func updateDispute(disputeId: String, request: DisputeRequests.UpdateDisputeRequest, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.updateDispute(disputeId: disputeId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func getDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.getDispute(disputeId: disputeId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func getDisputes(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int = 10, page: Int = 1, completionHandler: @escaping @Sendable (DisputeResponses.ListDisputesResponse?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.getDisputes(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(DisputeResponses.ListDisputesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func closeDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.closeDispute(disputeId: disputeId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
