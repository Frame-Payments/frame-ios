//
//  PhoneOTPVerificationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//
//  Frame networking for phone OTP verification (create + confirm).
//

import Foundation
import Frame

// Protocol for Mock Testing
protocol PhoneOTPVerificationProtocol {
    // async/await
    static func createVerification(accountId: String, phoneNumber: String, dateOfBirth: String) async throws -> (PhoneOTPVerificationCreateResponse?, NetworkingError?)
    static func confirmVerification(accountId: String, verificationId: String) async throws -> (PhoneOTPVerificationConfirmResponse?, NetworkingError?)

    // completionHandlers
    static func createVerification(accountId: String, phoneNumber: String, dateOfBirth: String, completionHandler: @escaping @Sendable (PhoneOTPVerificationCreateResponse?, NetworkingError?) -> Void)
    static func confirmVerification(accountId: String, verificationId: String, completionHandler: @escaping @Sendable (PhoneOTPVerificationConfirmResponse?, NetworkingError?) -> Void)
}

public final class PhoneOTPVerificationAPI: PhoneOTPVerificationProtocol, @unchecked Sendable {

    static func createVerification(accountId: String, phoneNumber: String, dateOfBirth: String) async throws -> (PhoneOTPVerificationCreateResponse?, NetworkingError?) {
        let endpoint = PhoneOTPVerificationEndpoints.create(accountId: accountId)
        let request = PhoneOTPVerificationRequests.CreateVerificationRequest(
            phoneNumber: phoneNumber,
            dateOfBirth: dateOfBirth
        )
        let requestBody = try FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PhoneOTPVerificationCreateResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    static func confirmVerification(accountId: String, verificationId: String) async throws -> (PhoneOTPVerificationConfirmResponse?, NetworkingError?) {
        let endpoint = PhoneOTPVerificationEndpoints.confirm(accountId: accountId, verificationId: verificationId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PhoneOTPVerificationConfirmResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // completionHandlers
    static func createVerification(accountId: String, phoneNumber: String, dateOfBirth: String, completionHandler: @escaping @Sendable (PhoneOTPVerificationCreateResponse?, NetworkingError?) -> Void) {
        let endpoint = PhoneOTPVerificationEndpoints.create(accountId: accountId)
        let request = PhoneOTPVerificationRequests.CreateVerificationRequest(
            phoneNumber: phoneNumber,
            dateOfBirth: dateOfBirth
        )
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PhoneOTPVerificationCreateResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    static func confirmVerification(accountId: String, verificationId: String, completionHandler: @escaping @Sendable (PhoneOTPVerificationConfirmResponse?, NetworkingError?) -> Void) {
        let endpoint = PhoneOTPVerificationEndpoints.confirm(accountId: accountId, verificationId: verificationId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PhoneOTPVerificationConfirmResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
