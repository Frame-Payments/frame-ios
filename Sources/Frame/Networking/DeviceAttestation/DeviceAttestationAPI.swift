//
//  DeviceAttestationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/14/26.
//

import Foundation

// Protocol for Mock Testing
protocol DeviceAttestationProtocol {
    // async/await
    static func getChallenge() async throws -> (DeviceAttestationRequests.ChallengeResponse?, NetworkingError?)
    static func attest(keyId: String, attestationObject: Data, challenge: String) async throws -> (DeviceAttestationRequests.AttestResponse?, NetworkingError?)

    // completionHandlers
    static func getChallenge(completionHandler: @escaping @Sendable (DeviceAttestationRequests.ChallengeResponse?, NetworkingError?) -> Void)
    static func attest(keyId: String, attestationObject: Data, challenge: String, completionHandler: @escaping @Sendable (DeviceAttestationRequests.AttestResponse?, NetworkingError?) -> Void)
}

public class DeviceAttestationAPI: DeviceAttestationProtocol, @unchecked Sendable {

    // async/await

    /// Requests a one-time challenge from the server for device attestation.
    public static func getChallenge() async throws -> (DeviceAttestationRequests.ChallengeResponse?, NetworkingError?) {
        let endpoint = DeviceAttestationEndpoints.challenge
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            usePublishableKey: true
        )
        if let data,
           let decoded = try? FrameNetworking.shared.jsonDecoder.decode(
               DeviceAttestationRequests.ChallengeResponse.self, from: data
           ) {
            return (decoded, error)
        }
        return (nil, error)
    }

    /// Sends the attestation object to the server for verification.
    public static func attest(keyId: String, attestationObject: Data, challenge: String) async throws -> (DeviceAttestationRequests.AttestResponse?, NetworkingError?) {
        let endpoint = DeviceAttestationEndpoints.attest
        let request = DeviceAttestationRequests.AttestRequest(
            keyId: keyId,
            attestationObject: attestationObject.base64EncodedString(),
            challenge: challenge
        )
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: requestBody,
            usePublishableKey: true
        )
        if let data,
           let decoded = try? FrameNetworking.shared.jsonDecoder.decode(
               DeviceAttestationRequests.AttestResponse.self, from: data
           ) {
            return (decoded, error)
        }
        return (nil, error)
    }

    // completionHandlers

    /// Requests a one-time challenge from the server for device attestation.
    public static func getChallenge(completionHandler: @escaping @Sendable (DeviceAttestationRequests.ChallengeResponse?, NetworkingError?) -> Void) {
        let endpoint = DeviceAttestationEndpoints.challenge

        FrameNetworking.shared.performDataTask(endpoint: endpoint, usePublishableKey: true) { data, response, error in
            if let data,
               let decoded = try? FrameNetworking.shared.jsonDecoder.decode(
                   DeviceAttestationRequests.ChallengeResponse.self, from: data
               ) {
                completionHandler(decoded, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Sends the attestation object to the server for verification.
    public static func attest(
        keyId: String, attestationObject: Data, challenge: String, completionHandler: @escaping @Sendable (DeviceAttestationRequests.AttestResponse?, NetworkingError?) -> Void) {
        let endpoint = DeviceAttestationEndpoints.attest
        let request = DeviceAttestationRequests.AttestRequest(
            keyId: keyId,
            attestationObject: attestationObject.base64EncodedString(),
            challenge: challenge
        )
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, usePublishableKey: true) { data, response, error in
            if let data,
               let decoded = try? FrameNetworking.shared.jsonDecoder.decode(
                   DeviceAttestationRequests.AttestResponse.self, from: data
               ) {
                completionHandler(decoded, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
