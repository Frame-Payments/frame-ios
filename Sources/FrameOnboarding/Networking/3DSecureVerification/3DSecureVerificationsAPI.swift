//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/2/26.
//

import Foundation
import Frame

protocol ThreeDSecureVerificationsProtocol {
    // async/await
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification) async throws -> (ThreeDSecureVerification?, NetworkingError?)
    static func retrieve3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?)
    static func confirm3DSecureVerification(verificationId: String, request: ThreeDSecureRequests.ConfirmThreeDSecureVerification) async throws -> (ThreeDSecureVerification?, NetworkingError?)
    static func resend3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?)
    
    //completionHandlers
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)
    static func retrieve3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)
    static func confirm3DSecureVerification(verificationId: String, request: ThreeDSecureRequests.ConfirmThreeDSecureVerification, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)
    static func resend3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)
}

class ThreeDSecureVerificationsAPI: ThreeDSecureVerificationsProtocol, @unchecked Sendable {
    // async/await
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification) async throws -> (ThreeDSecureVerification?, Frame.NetworkingError?) {
        let endpoint = ThreeDSecureEndpoints.create3DSecureVerification
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func retrieve3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, Frame.NetworkingError?) {
        let endpoint = ThreeDSecureEndpoints.retrieve3DSecureVerification(verificationId: verificationId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func confirm3DSecureVerification(verificationId: String, request: ThreeDSecureRequests.ConfirmThreeDSecureVerification) async throws -> (ThreeDSecureVerification?, NetworkingError?) {
        let endpoint = ThreeDSecureEndpoints.confirm3DSecureVerification(verificationId: verificationId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func resend3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?) {
        let endpoint = ThreeDSecureEndpoints.resend3DSecureVerification(verificationId: verificationId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //completionHandlers
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, Frame.NetworkingError?) -> Void) {
        let endpoint = ThreeDSecureEndpoints.create3DSecureVerification
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func retrieve3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, Frame.NetworkingError?) -> Void) {
        let endpoint = ThreeDSecureEndpoints.retrieve3DSecureVerification(verificationId: verificationId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func confirm3DSecureVerification(verificationId: String, request: ThreeDSecureRequests.ConfirmThreeDSecureVerification, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, Frame.NetworkingError?) -> Void) {
        let endpoint = ThreeDSecureEndpoints.confirm3DSecureVerification(verificationId: verificationId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func resend3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, Frame.NetworkingError?) -> Void) {
        let endpoint = ThreeDSecureEndpoints.resend3DSecureVerification(verificationId: verificationId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
