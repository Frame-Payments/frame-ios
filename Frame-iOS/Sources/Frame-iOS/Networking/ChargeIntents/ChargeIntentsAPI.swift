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
    func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent?
    func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> FrameObjects.ChargeIntent?
    func confirmChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent?
    func cancelChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent?
    func getAllChargeIntents(page: Int?, perPage: Int?) async throws -> [FrameObjects.ChargeIntent]?
    func getChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent?
    func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent?
    
    // completionHandlers
    func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func getAllChargeIntents(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable ([FrameObjects.ChargeIntent]?) -> Void)
    func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
}

// Charge Intents API
public class ChargeIntentsAPI: ChargeIntentsProtocol, @unchecked Sendable {
    public init() {}
    
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    
    //async/await
    public func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.createChargeIntent
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func confirmChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func cancelChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil) async throws -> [FrameObjects.ChargeIntent]? {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    // completionHandlers
    func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.createChargeIntent
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable ([FrameObjects.ChargeIntent]?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
