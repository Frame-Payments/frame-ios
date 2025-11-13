//
//  RefundsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

// https://docs.framepayments.com/api/refunds

// Protocol for Mock Testing
protocol RefundsProtocol {
    //async/await
    static func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> (FrameObjects.Refund?, NetworkingError?)
    static func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?) async throws -> (RefundResponses.ListRefundsResponse?, NetworkingError?)
    static func getRefundWith(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?)
    static func cancelRefund(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?)
    
    // completionHandlers
    static func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void)
    static func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?, completionHandler: @escaping @Sendable (RefundResponses.ListRefundsResponse?, NetworkingError?) -> Void)
    static func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void)
    static func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void)
}

// Refunds API
public class RefundsAPI: RefundsProtocol, @unchecked Sendable {
    //async/await
    public static func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> (FrameObjects.Refund?, NetworkingError?) {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            SiftManager.addNewSiftEvent(transactionType: .refund, eventId: decodedResponse.id)
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getRefunds(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int? = nil, page: Int? = nil) async throws -> (RefundResponses.ListRefundsResponse?, NetworkingError?) {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(RefundResponses.ListRefundsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getRefundWith(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?) {
        guard !refundId.isEmpty else { return (nil, nil) }
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func cancelRefund(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?) {
        guard !refundId.isEmpty else { return (nil, nil) }
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    // completionHandlers
    public static func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                SiftManager.addNewSiftEvent(transactionType: .refund, eventId: decodedResponse.id)
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getRefunds(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int? = nil, page: Int? = nil, completionHandler: @escaping @Sendable (RefundResponses.ListRefundsResponse?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(RefundResponses.ListRefundsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
