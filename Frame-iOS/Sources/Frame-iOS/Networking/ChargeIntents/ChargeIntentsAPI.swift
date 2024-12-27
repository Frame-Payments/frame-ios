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
    static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent?
    static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> FrameObjects.ChargeIntent?
    static func confirmChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent?
    static func cancelChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent?
    static func getAllChargeIntents(page: Int?, perPage: Int?) async throws -> [FrameObjects.ChargeIntent]?
    static func getChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent?
    static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent?
    
    // completionHandlers
    static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    static func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    static func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    static func getAllChargeIntents(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable ([FrameObjects.ChargeIntent]?) -> Void)
    static func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
    static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void)
}

// Charge Intents API
public class ChargeIntentsAPI: ChargeIntentsProtocol, @unchecked Sendable {
    //async/await
    public static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.createChargeIntent
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> FrameObjects.ChargeIntent? {
        guard !intentId.isEmpty else { return nil }
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func confirmChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        guard !intentId.isEmpty else { return nil }
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func cancelChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        guard !intentId.isEmpty else { return nil }
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil) async throws -> [FrameObjects.ChargeIntent]? {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public static func getChargeIntent(intentId: String) async throws -> FrameObjects.ChargeIntent? {
        guard !intentId.isEmpty else { return nil }
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> FrameObjects.ChargeIntent? {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    // completionHandlers
    public static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.createChargeIntent
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable ([FrameObjects.ChargeIntent]?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public static func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?) -> Void) {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
