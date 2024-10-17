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
    func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> FrameObjects.Refund?
    func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?) async throws -> [FrameObjects.Refund]?
    func getRefundWith(refundId: String) async throws -> FrameObjects.Refund?
    func cancelRefund(refundId: String) async throws -> FrameObjects.Refund?
    
    // completionHandlers
    func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void)
    func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?, completionHandler: @escaping @Sendable ([FrameObjects.Refund]?) -> Void)
    func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void)
    func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void)
}

// Refunds API
public class RefundsAPI: RefundsProtocol, @unchecked Sendable {
    
    public init() {}
    
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    
    //async/await
    func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> FrameObjects.Refund? {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page: Int?) async throws -> [FrameObjects.Refund]? {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(RefundResponses.ListRefundsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    func getRefundWith(refundId: String) async throws -> FrameObjects.Refund? {
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    func cancelRefund(refundId: String) async throws -> FrameObjects.Refund? {
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.Refund.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    // completionHandlers
    func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void) {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page: Int?, completionHandler: @escaping @Sendable ([FrameObjects.Refund]?) -> Void) {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(RefundResponses.ListRefundsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void) {
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?) -> Void) {
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
