//
//  ChargeIntentsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

// Protocol for Mock Testing
protocol ChargeIntentsProtocol {
    //async/await
    func createCharge(request: ChargeRequests.CreateChargeRequest) async throws -> FrameObjects.ChargeIntent?
    func captureCharge(intentId: String, request: ChargeRequests.CaptureChargeRequest) async throws -> FrameObjects.ChargeIntent?
    func confirmCharge(intentId: String) async throws -> FrameObjects.ChargeIntent?
    func cancelCharge(intentId: String) async throws -> FrameObjects.ChargeIntent?
    func getAllCharges() async throws -> [FrameObjects.ChargeIntent]?
    func getChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent?
    func updateCharge(intentId: String, request: ChargeRequests.UpdateChargeRequest) async throws -> FrameObjects.ChargeIntent?
    
    // completionHandlers
    func createCharge(request: ChargeRequests.CreateChargeRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func captureCharge(intentId: String, request: ChargeRequests.CaptureChargeRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func confirmCharge(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func cancelCharge(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func getAllCharges(completionHandler: @escaping @Sendable ([FrameObjects.ChargeIntent]?) -> Void)
    func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func updateCharge(intentId: String, request: ChargeRequests.UpdateChargeRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
}

public class ChargeIntentsAPI: ChargeIntentsProtocol, @unchecked Sendable {
    
    public init() {}
    
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    
    //async/await
    public func createCharge(request: ChargeRequests.CreateChargeRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeEndpoints.createCharge
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func captureCharge(intentId: String, request: ChargeRequests.CaptureChargeRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeEndpoints.captureCharge(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func confirmCharge(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeEndpoints.confirmCharge(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func cancelCharge(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeEndpoints.cancelCharge(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getAllCharges() async throws -> [FrameObjects.ChargeIntent]? {
        let endpoint = ChargeEndpoints.getAllCharges
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(ChargeResponses.ListChargeIntentsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeEndpoints.getCharge(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updateCharge(intentId: String, request: ChargeRequests.UpdateChargeRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeEndpoints.updateCharge(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    // completionHandlers
    func createCharge(request: ChargeRequests.CreateChargeRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeEndpoints.createCharge
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func captureCharge(intentId: String, request: ChargeRequests.CaptureChargeRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeEndpoints.captureCharge(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func confirmCharge(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeEndpoints.confirmCharge(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func cancelCharge(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeEndpoints.cancelCharge(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getAllCharges(completionHandler: @escaping @Sendable ([FrameObjects.ChargeIntent]?) -> Void) {
        let endpoint = ChargeEndpoints.getAllCharges
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(ChargeResponses.ListChargeIntentsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeEndpoints.getCharge(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updateCharge(intentId: String, request: ChargeRequests.UpdateChargeRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeEndpoints.updateCharge(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
