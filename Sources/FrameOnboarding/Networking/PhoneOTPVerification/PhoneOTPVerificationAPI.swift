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

/// Internal protocol used for mock-testing the phone OTP verification API surface.
protocol PhoneOTPVerificationProtocol {
    // async/await
    /// Creates a new phone OTP verification for the given account.
    static func createVerification(accountId: String, phoneNumber: String, dateOfBirth: String) async throws -> (PhoneOTPVerificationCreateResponse?, NetworkingError?)
    /// Confirms an existing phone OTP verification using an optional OTP code.
    static func confirmVerification(accountId: String, verificationId: String, code: String?) async throws -> (PhoneOTPVerificationConfirmResponse?, NetworkingError?)

    // completionHandlers
    /// Completion-handler variant of ``createVerificationAsync(_:)``.
    static func createVerification(accountId: String, phoneNumber: String, dateOfBirth: String, completionHandler: @escaping @Sendable (PhoneOTPVerificationCreateResponse?, NetworkingError?) -> Void)
    /// Completion-handler variant of ``confirmVerificationAsync(_:)``.
    static func confirmVerification(accountId: String, verificationId: String, code: String?, completionHandler: @escaping @Sendable (PhoneOTPVerificationConfirmResponse?, NetworkingError?) -> Void)
}

/// Manages the phone OTP verification resource, providing methods to create and confirm
/// phone-based one-time-password verifications on behalf of a Frame account.
public final class PhoneOTPVerificationAPI: PhoneOTPVerificationProtocol, @unchecked Sendable {
    /// Creates a new phone OTP verification for the specified account.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account identifier to associate with the verification.
    ///   - phoneNumber: The phone number to send the OTP to.
    ///   - dateOfBirth: The account holder's date of birth in `YYYY-MM-DD` format.
    /// - Returns: A tuple containing the decoded ``PhoneOTPVerificationCreateResponse`` on success, or a ``NetworkingError`` on failure.
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

    /// Confirms an existing phone OTP verification.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account identifier associated with the verification.
    ///   - verificationId: The identifier of the verification session to confirm.
    ///   - code: The OTP code supplied by the user. Pass `nil` when using the Prove identity path, which does not require a code.
    /// - Returns: A tuple containing the decoded ``PhoneOTPVerificationConfirmResponse`` on success, or a ``NetworkingError`` on failure.
    static func confirmVerification(accountId: String, verificationId: String, code: String? = nil) async throws -> (PhoneOTPVerificationConfirmResponse?, NetworkingError?) {
        let endpoint = PhoneOTPVerificationEndpoints.confirm(accountId: accountId, verificationId: verificationId)
        var requestBody: Data?
        if let code {
            let request = PhoneOTPVerificationRequests.ConfirmVerificationRequest(code: code)
            requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        }

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PhoneOTPVerificationConfirmResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // completionHandlers
    /// Completion-handler variant of `createVerification(accountId:phoneNumber:dateOfBirth:)`.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account identifier to associate with the verification.
    ///   - phoneNumber: The phone number to send the OTP to.
    ///   - dateOfBirth: The account holder's date of birth in `YYYY-MM-DD` format.
    ///   - completionHandler: Called with the decoded ``PhoneOTPVerificationCreateResponse`` and any ``NetworkingError``.
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

    /// Completion-handler variant of `confirmVerification(accountId:verificationId:code:)`.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account identifier associated with the verification.
    ///   - verificationId: The identifier of the verification session to confirm.
    ///   - code: The OTP code supplied by the user, or `nil` for the Prove identity path.
    ///   - completionHandler: Called with the decoded ``PhoneOTPVerificationConfirmResponse`` and any ``NetworkingError``.
    static func confirmVerification(accountId: String, verificationId: String, code: String? = nil, completionHandler: @escaping @Sendable (PhoneOTPVerificationConfirmResponse?, NetworkingError?) -> Void) {
        let endpoint = PhoneOTPVerificationEndpoints.confirm(accountId: accountId, verificationId: verificationId)
        var requestBody: Data?
        if let code {
            let request = PhoneOTPVerificationRequests.ConfirmVerificationRequest(code: code)
            requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        }
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PhoneOTPVerificationConfirmResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
