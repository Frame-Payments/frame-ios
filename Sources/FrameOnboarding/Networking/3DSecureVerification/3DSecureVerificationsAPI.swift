//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/2/26.
//

import Foundation
import Frame

/// Internal protocol describing the interface for creating, retrieving, and resending 3D Secure verifications.
protocol ThreeDSecureVerificationsProtocol {
    // async/await

    /// Creates a new 3D Secure verification using the provided request body.
    /// - Parameter request: The creation request containing cardholder and payment details.
    /// - Returns: A tuple of the created ``ThreeDSecureVerification``, an optional domain-level ``ThreeDSecureVerificationError``, and an optional ``NetworkingError``.
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification) async throws -> (ThreeDSecureVerification?, ThreeDSecureVerificationError?, NetworkingError?)

    /// Retrieves an existing 3D Secure verification by its identifier.
    /// - Parameter verificationId: The unique identifier of the verification to retrieve.
    /// - Returns: A tuple of the retrieved ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
    static func retrieve3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?)

    /// Resends a 3D Secure verification challenge for the given verification identifier.
    /// - Parameter verificationId: The unique identifier of the verification to resend.
    /// - Returns: A tuple of the updated ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
    static func resend3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?)

    //completionHandlers

    /// Completion-handler variant of ``create3DSecureVerification(request:)``.
    /// - Parameters:
    ///   - request: The creation request containing cardholder and payment details.
    ///   - completionHandler: Called with the created ``ThreeDSecureVerification``, an optional domain-level ``ThreeDSecureVerificationError``, and an optional ``NetworkingError``.
    static func create3DSecureVerification(request: ThreeDSecureRequests.CreateThreeDSecureVerification, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, ThreeDSecureVerificationError?, NetworkingError?) -> Void)

    /// Completion-handler variant of ``retrieve3DSecureVerification(verificationId:)``.
    /// - Parameters:
    ///   - verificationId: The unique identifier of the verification to retrieve.
    ///   - completionHandler: Called with the retrieved ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
    static func retrieve3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)

    /// Completion-handler variant of ``resend3DSecureVerification(verificationId:)``.
    /// - Parameters:
    ///   - verificationId: The unique identifier of the verification to resend.
    ///   - completionHandler: Called with the updated ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
    static func resend3DSecureVerification(verificationId: String, completionHandler: @escaping @Sendable (ThreeDSecureVerification?, NetworkingError?) -> Void)
}

/// API class that manages 3D Secure verification resources, providing methods to create, retrieve, and resend verifications.
public class ThreeDSecureVerificationsAPI: ThreeDSecureVerificationsProtocol, @unchecked Sendable {
    // async/await

    /// Creates a new 3D Secure verification using the provided request body.
    /// - Parameter request: The creation request containing cardholder and payment details.
    /// - Returns: A tuple of the created ``ThreeDSecureVerification``, an optional domain-level ``ThreeDSecureVerificationError``, and an optional ``NetworkingError``.
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

    /// Retrieves an existing 3D Secure verification by its identifier.
    /// - Parameter verificationId: The unique identifier of the verification to retrieve.
    /// - Returns: A tuple of the retrieved ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
    static func retrieve3DSecureVerification(verificationId: String) async throws -> (ThreeDSecureVerification?, NetworkingError?) {
        let endpoint = ThreeDSecureEndpoints.retrieve3DSecureVerification(verificationId: verificationId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ThreeDSecureVerification.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Resends a 3D Secure verification challenge for the given verification identifier.
    /// - Parameter verificationId: The unique identifier of the verification to resend.
    /// - Returns: A tuple of the updated ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
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

    /// Completion-handler variant of ``create3DSecureVerification(request:)``.
    /// - Parameters:
    ///   - request: The creation request containing cardholder and payment details.
    ///   - completionHandler: Called with the created ``ThreeDSecureVerification``, an optional domain-level ``ThreeDSecureVerificationError``, and an optional ``NetworkingError``.
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

    /// Completion-handler variant of ``retrieve3DSecureVerification(verificationId:)``.
    /// - Parameters:
    ///   - verificationId: The unique identifier of the verification to retrieve.
    ///   - completionHandler: Called with the retrieved ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
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

    /// Completion-handler variant of ``resend3DSecureVerification(verificationId:)``.
    /// - Parameters:
    ///   - verificationId: The unique identifier of the verification to resend.
    ///   - completionHandler: Called with the updated ``ThreeDSecureVerification`` and an optional ``NetworkingError``.
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
