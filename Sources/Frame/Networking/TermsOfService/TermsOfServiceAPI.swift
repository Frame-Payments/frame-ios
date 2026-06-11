//
//  TermsOfServiceAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/19/26.
//

import Foundation

/// API client for the Terms of Service resource.
///
/// Provides static methods for creating a Terms of Service token and recording
/// a user's acceptance of a specific agreement version.
public class TermsOfServiceAPI {

    // MARK: async/await

    /// Creates a new Terms of Service token representing the current agreement version.
    ///
    /// - Returns: A tuple containing the ``FrameObjects/TermsOfServiceTokenResponse`` on success,
    ///   or a ``NetworkingError`` if the request fails.
    public static func createToken() async throws -> (FrameObjects.TermsOfServiceTokenResponse?, NetworkingError?) {
        let endpoint = TermsOfServiceEndpoints.createToken
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode([String: String]())

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decoded = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.TermsOfServiceTokenResponse.self, from: data) {
            return (decoded, error)
        }
        return (nil, error)
    }

    /// Records a user's acceptance of the Terms of Service.
    ///
    /// - Parameter request: A ``TermsOfServiceRequest/UpdateRequest`` containing the token
    ///   and optional acceptance metadata such as timestamp, IP address, and user-agent.
    /// - Returns: A tuple containing the updated ``FrameObjects/TermsOfServiceTokenResponse``
    ///   on success, or a ``NetworkingError`` if the request fails.
    public static func update(request: TermsOfServiceRequest.UpdateRequest) async throws -> (FrameObjects.TermsOfServiceTokenResponse?, NetworkingError?) {
        let endpoint = TermsOfServiceEndpoints.update
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decoded = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.TermsOfServiceTokenResponse.self, from: data) {
            return (decoded, error)
        }
        return (nil, error)
    }

    // MARK: Completion handlers

    /// Completion-handler variant of ``createToken()``.
    ///
    /// - Parameter completionHandler: Called with the ``FrameObjects/TermsOfServiceTokenResponse``
    ///   on success, or a ``NetworkingError`` if the request fails.
    public static func createToken(completionHandler: @escaping @Sendable (FrameObjects.TermsOfServiceTokenResponse?, NetworkingError?) -> Void) {
        let endpoint = TermsOfServiceEndpoints.createToken
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode([String: String]())

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, _, error in
            if let data, let decoded = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.TermsOfServiceTokenResponse.self, from: data) {
                completionHandler(decoded, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``update(request:)``.
    ///
    /// - Parameters:
    ///   - request: A ``TermsOfServiceRequest/UpdateRequest`` containing the token
    ///     and optional acceptance metadata.
    ///   - completionHandler: Called with the updated ``FrameObjects/TermsOfServiceTokenResponse``
    ///     on success, or a ``NetworkingError`` if the request fails.
    public static func update(request: TermsOfServiceRequest.UpdateRequest, completionHandler: @escaping @Sendable (FrameObjects.TermsOfServiceTokenResponse?, NetworkingError?) -> Void) {
        let endpoint = TermsOfServiceEndpoints.update
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, _, error in
            if let data, let decoded = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.TermsOfServiceTokenResponse.self, from: data) {
                completionHandler(decoded, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
