//
//  RefundsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

// https://docs.framepayments.com/refunds

// Protocol for Mock Testing
protocol RefundsProtocol {
    //async/await
    static func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> FrameObjects.Refund?
    static func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?) async throws -> [FrameObjects.Refund]?
    static func getRefundWith(refundId: String) async throws -> FrameObjects.Refund?
    static func cancelRefund(refundId: String) async throws -> FrameObjects.Refund?
    
    // completionHandlers
    static func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void)
    static func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?, completionHandler: @escaping @Sendable ([FrameObjects.Refund]?) -> Void)
    static func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void)
    static func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void)
}

// Refunds API
public class RefundsAPI: RefundsProtocol, @unchecked Sendable {
    //async/await
    public static func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> FrameObjects.Refund? {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func getRefunds(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int? = nil, page: Int? = nil) async throws -> [FrameObjects.Refund]? {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(RefundResponses.ListRefundsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public static func getRefundWith(refundId: String) async throws -> FrameObjects.Refund? {
        guard !refundId.isEmpty else { return nil }
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func cancelRefund(refundId: String) async throws -> FrameObjects.Refund? {
        guard !refundId.isEmpty else { return nil }
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    // completionHandlers
    public static func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void) {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    public static func getRefunds(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int? = nil, page: Int? = nil, completionHandler: @escaping @Sendable ([FrameObjects.Refund]?) -> Void) {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(RefundResponses.ListRefundsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    public static func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void) {
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    public static func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void) {
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
}
