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
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification) async throws -> (ThreeDSecureVerification?, ThreeDSecureVerificationError?, NetworkingError?)
    static func retrieve3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?)
    static func resend3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?)
    
    //completionHandlers
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, ThreeDSecureVerificationError?, NetworkingError?) -> Void)
    static func retrieve3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)
    static func resend3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)
}

class ThreeDSecureVerificationsAPI: ThreeDSecureVerificationsProtocol, @unchecked Sendable {
    // async/await
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification) async throws -> (ThreeDSecureVerification?, ThreeDSecureVerificationError?, NetworkingError?) {
        let endpoint = ThreeDSecureEndpoints.create3DSecureVerification
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
            return (decodedResponse, nil, error)
        } else if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerificationError.self, from: data) {
            return (nil, decodedResponse, error)
        } else {
            return (nil, nil, error)
        }
    }
    
    static func retrieve3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?) {
        let endpoint = ThreeDSecureEndpoints.retrieve3DSecureVerification(verificationId: verificationId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
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
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, ThreeDSecureVerificationError?, NetworkingError?) -> Void) {
        let endpoint = ThreeDSecureEndpoints.create3DSecureVerification
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
                completionHandler(decodedResponse, nil, error)
            } else if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerificationError.self, from: data) {
                completionHandler(nil, decodedResponse, error)
            } else {
                completionHandler(nil, nil, error)
            }
        }
    }
    
    static func retrieve3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void) {
        let endpoint = ThreeDSecureEndpoints.retrieve3DSecureVerification(verificationId: verificationId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func resend3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void) {
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
