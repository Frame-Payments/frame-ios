//
//  PhoneOTPVerificationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//
//  Concrete ProveAuthBackend using Frame networking (phone-otp endpoints).
//

import Foundation
import Frame

/// Backend implementation that fetches Prove auth token and verify via Frame's phone-otp endpoints.
/// Conforms to ProveAuthBackend for use with ProveAuthService.
public final class PhoneOTPVerificationAPI: ProveAuthBackend, @unchecked Sendable {
    public init() {}

    public func getAuthToken(phoneNumber: String, dateOfBirth: String, flowType: String) async throws -> String {
        let endpoint = PhoneOTPVerificationEndpoints.initialize
        let request = PhoneOTPVerificationRequests.Initialize(
            phoneNumber: phoneNumber,
            dateOfBirth: dateOfBirth,
            flowType: flowType
        )
        let requestBody = try FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, networkingError) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: requestBody
        )

        if let networkingError {
            throw PhoneOTPVerificationAPIError.networking(networkingError)
        }

        guard let data else {
            throw PhoneOTPVerificationAPIError.missingData
        }

        if let errorResponse = try? FrameNetworking.shared.jsonDecoder.decode(
            PhoneOTPVerificationError.self,
            from: data
        ), let detail = errorResponse.error {
            throw PhoneOTPVerificationAPIError.server(message: detail.message ?? "Unknown error")
        }

        guard let response = try? FrameNetworking.shared.jsonDecoder.decode(
            PhoneOTPVerificationInitializeResponse.self,
            from: data
        ) else {
            throw PhoneOTPVerificationAPIError.missingAuthToken
        }

        return response.authToken
    }

    public func verify(authId: String) async throws -> ProveUserInfo {
        let endpoint = PhoneOTPVerificationEndpoints.verify
        let request = PhoneOTPVerificationRequests.Verify(authId: authId)
        let requestBody = try FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, networkingError) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: requestBody
        )

        if let networkingError {
            throw PhoneOTPVerificationAPIError.networking(networkingError)
        }

        guard let data else {
            throw PhoneOTPVerificationAPIError.missingData
        }

        if let errorResponse = try? FrameNetworking.shared.jsonDecoder.decode(
            PhoneOTPVerificationError.self,
            from: data
        ), let detail = errorResponse.error {
            throw PhoneOTPVerificationAPIError.server(message: detail.message ?? "Unknown error")
        }

        guard let response = try? FrameNetworking.shared.jsonDecoder.decode(
            PhoneOTPVerificationVerifyResponse.self,
            from: data
        ) else {
            throw PhoneOTPVerificationAPIError.missingUserInfo
        }

        return ProveUserInfo(firstName: response.firstName, lastName: response.lastName)
    }
}

public enum PhoneOTPVerificationAPIError: Error, Sendable {
    case missingData
    case missingAuthToken
    case missingUserInfo
    case networking(NetworkingError)
    case server(message: String)
}
