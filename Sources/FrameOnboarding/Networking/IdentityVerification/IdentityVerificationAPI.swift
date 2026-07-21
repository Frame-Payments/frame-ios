//
//  IdentityVerificationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//
//  Frame networking for the no-SSN government-ID identity-verification (IDV) flow:
//  create a Persona inquiry server-side, then confirm its result.
//

import Foundation
import Frame

/// Internal protocol used for mock-testing the identity-verification API surface.
protocol IdentityVerificationProtocol {
    /// Creates an IDV session, returning the pre-created Persona `inquiry_id` to launch the SDK against.
    static func createSession() async throws -> (IDVSessionResponse?, NetworkingError?)
    /// Confirms a completed Persona inquiry and returns the authoritative `verified` result.
    static func complete(inquiryId: String) async throws -> (IDVCompleteResponse?, NetworkingError?)
}

/// Manages the identity-verification resource for the no-SSN onboarding path, providing methods
/// to create a Persona inquiry session and confirm its result with the Frame backend.
///
/// Requests authenticate with the active onboarding-session token (`onb_sess_…`), so the server
/// resolves the account from the session — no `accountId` is passed.
public final class IdentityVerificationAPI: IdentityVerificationProtocol, @unchecked Sendable {
    /// Creates an IDV session. The server pre-fills and creates the Persona inquiry.
    ///
    /// - Returns: A tuple containing the decoded ``IDVSessionResponse`` (with the `inquiry_id` to
    ///   launch the Persona SDK against) on success, or a ``NetworkingError`` on failure.
    static func createSession() async throws -> (IDVSessionResponse?, NetworkingError?) {
        let endpoint = IdentityVerificationEndpoints.createSession

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(IDVSessionResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Confirms a completed Persona inquiry (JSON variant of `POST /idv/complete`).
    ///
    /// The decoded ``IDVCompleteResponse/verified`` flag is the source of truth for verification —
    /// the Persona client callbacks are best-effort only. A non-JSON or error response decodes to
    /// `nil`, which callers should treat as "pending / not yet verified" rather than a failure.
    ///
    /// - Parameter inquiryId: The Persona inquiry identifier returned by ``createSession()``.
    /// - Returns: A tuple containing the decoded ``IDVCompleteResponse`` on success, or a ``NetworkingError`` on failure.
    static func complete(inquiryId: String) async throws -> (IDVCompleteResponse?, NetworkingError?) {
        let endpoint = IdentityVerificationEndpoints.complete
        let request = IdentityVerificationRequests.CompleteRequest(inquiryId: inquiryId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(IDVCompleteResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
}
