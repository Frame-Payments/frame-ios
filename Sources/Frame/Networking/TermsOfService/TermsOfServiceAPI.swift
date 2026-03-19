//
//  TermsOfServiceAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/19/26.
//

import Foundation

public class TermsOfServiceAPI {

    // MARK: async/await

    public static func createToken() async throws -> (FrameObjects.TermsOfServiceTokenResponse?, NetworkingError?) {
        let endpoint = TermsOfServiceEndpoints.createToken
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode([String: String]())

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decoded = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.TermsOfServiceTokenResponse.self, from: data) {
            return (decoded, error)
        }
        return (nil, error)
    }

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
