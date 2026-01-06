//
//  SessionsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/17/25.
//

import Foundation
import Frame


// Protocol for Mock Testing
protocol SessionsProtocol {
    //async/await
    static func createOnboardingSession(request: SessionRequests.CreateOnboardingSession) async throws -> (OnboardingSession?, NetworkingError?)
    static func getOnboardingSessionWithCustomer(customerId: String) async throws -> (SessionResponses.ListSessionsResponse?, NetworkingError?)
    static func cancelOnboardingSession(sessionId: String) async throws -> (OnboardingSession?, NetworkingError?)
    
    // completionHandlers
    static func createOnboardingSession(request: SessionRequests.CreateOnboardingSession, completionHandler: @escaping @Sendable (OnboardingSession?, NetworkingError?) -> Void)
    static func getOnboardingSessionWithCustomer(customerId: String, completionHandler: @escaping @Sendable (SessionResponses.ListSessionsResponse?, NetworkingError?) -> Void)
    static func cancelOnboardingSession(sessionId: String, completionHandler: @escaping @Sendable (OnboardingSession?, NetworkingError?) -> Void)
}

// Sessions API
class SessionsAPI: SessionsProtocol, @unchecked Sendable {
    //async/await
    static func createOnboardingSession(request: SessionRequests.CreateOnboardingSession) async throws -> (OnboardingSession?, NetworkingError?) {
        let endpoint = SessionEndpoints.createOnboardingSession
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(OnboardingSession.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func getOnboardingSessionWithCustomer(customerId: String) async throws -> (SessionResponses.ListSessionsResponse?, NetworkingError?) {
        let endpoint = SessionEndpoints.getOnboardingSessionWithCustomer(customerId: customerId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SessionResponses.ListSessionsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func cancelOnboardingSession(sessionId: String) async throws -> (OnboardingSession?, NetworkingError?) {
        let endpoint = SessionEndpoints.cancelOnboardingSession(sessionId: sessionId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(OnboardingSession.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    // completionHandlers
    static func createOnboardingSession(request: SessionRequests.CreateOnboardingSession, completionHandler: @escaping @Sendable (OnboardingSession?, NetworkingError?) -> Void) {
        let endpoint = SessionEndpoints.createOnboardingSession
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(OnboardingSession.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func getOnboardingSessionWithCustomer(customerId: String, completionHandler: @escaping @Sendable (SessionResponses.ListSessionsResponse?, NetworkingError?) -> Void) {
        let endpoint = SessionEndpoints.getOnboardingSessionWithCustomer(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(SessionResponses.ListSessionsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func cancelOnboardingSession(sessionId: String, completionHandler: @escaping @Sendable (OnboardingSession?, NetworkingError?) -> Void) {
        let endpoint = SessionEndpoints.cancelOnboardingSession(sessionId: sessionId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(OnboardingSession.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
