//
//  DeviceAttestationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/14/26.
//

import Foundation

/// Internal protocol used to abstract device-attestation network calls for mock testing.
protocol DeviceAttestationProtocol {
    // async/await
    /// Fetches a one-time challenge from the server.
    static func getChallenge() async throws -> (DeviceAttestationRequests.ChallengeResponse?, NetworkingError?)
    /// Submits the attestation object and challenge to the server for verification.
    static func attest(keyId: String, attestationObject: Data, challenge: String) async throws -> (DeviceAttestationRequests.AttestResponse?, NetworkingError?)

    // completionHandlers
    /// Completion-handler variant of ``getChallenge()``.
    static func getChallenge(completionHandler: @escaping @Sendable (DeviceAttestationRequests.ChallengeResponse?, NetworkingError?) -> Void)
    /// Completion-handler variant of ``attest(keyId:attestationObject:challenge:)``.
    static func attest(keyId: String, attestationObject: Data, challenge: String, completionHandler: @escaping @Sendable (DeviceAttestationRequests.AttestResponse?, NetworkingError?) -> Void)
}

/// Manages device-attestation API calls, providing both async/await and completion-handler
/// interfaces for obtaining server challenges and submitting attestation objects.
public class DeviceAttestationAPI: DeviceAttestationProtocol, @unchecked Sendable {

    // async/await

    /// Requests a one-time challenge from the server for device attestation.
    ///
    /// - Returns: A tuple containing the decoded ``DeviceAttestationRequests/ChallengeResponse``
    ///   on success, or a ``NetworkingError`` on failure.
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

    /// Sends the device attestation object and associated challenge to the server for verification.
    ///
    /// - Parameters:
    ///   - keyId: The identifier of the App Attest key used to generate the attestation.
    ///   - attestationObject: The raw attestation object returned by the App Attest framework.
    ///   - challenge: The one-time challenge previously obtained via ``getChallenge()``.
    /// - Returns: A tuple containing the decoded ``DeviceAttestationRequests/AttestResponse``
    ///   on success, or a ``NetworkingError`` on failure.
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

    /// Completion-handler variant of ``getChallenge()``.
    ///
    /// - Parameter completionHandler: Called with the decoded ``DeviceAttestationRequests/ChallengeResponse``
    ///   and any ``NetworkingError`` encountered.
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

    /// Completion-handler variant of ``attest(keyId:attestationObject:challenge:)``.
    ///
    /// - Parameters:
    ///   - keyId: The identifier of the App Attest key used to generate the attestation.
    ///   - attestationObject: The raw attestation object returned by the App Attest framework.
    ///   - challenge: The one-time challenge previously obtained via ``getChallenge(completionHandler:)``.
    ///   - completionHandler: Called with the decoded ``DeviceAttestationRequests/AttestResponse``
    ///     and any ``NetworkingError`` encountered.
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
