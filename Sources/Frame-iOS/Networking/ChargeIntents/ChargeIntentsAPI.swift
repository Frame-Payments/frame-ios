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
    static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func confirmChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func cancelChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func getAllChargeIntents(page: Int?, perPage: Int?) async throws -> (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?)
    static func getChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    
    // completionHandlers
    static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func getAllChargeIntents(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?) -> Void)
    static func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
}

// Charge Intents API
public class ChargeIntentsAPI: ChargeIntentsProtocol, @unchecked Sendable {
    //async/await
    public static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        let endpoint = ChargeIntentEndpoints.createChargeIntent
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func confirmChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
//            SiftManager.addNewSiftEvent(transactionType: .authorize, eventId: decodedResponse.id)
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func cancelChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil) async throws -> (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?) {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    // completionHandlers
    public static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.createChargeIntent
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
//                SiftManager.addNewSiftEvent(transactionType: .authorize, eventId: decodedResponse.id)
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
