//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/2/26.
//

import Foundation

/// Represents the lifecycle state of a 3D Secure verification attempt.
enum VerificationStatus: String, Codable {
    /// The verification has been created but not yet completed.
    case pending
    /// The verification challenge was completed successfully.
    case succeeded
    /// The verification challenge failed or was declined.
    case failed
    /// A verification challenge URL has been issued and is awaiting user interaction.
    case issued
}

/// A 3D Secure verification object returned by the Frame API.
struct ThreeDSecureVerification: Codable {
    /// Unique identifier for the verification object.
    let id: String
    /// Identifier of the customer associated with this verification.
    let customer: String
    /// Identifier of the payment method being verified.
    let paymentMethod: String
    /// API object type string (e.g. `"three_d_secure_verification"`).
    let object: String
    /// Indicates whether this object exists in live mode (`true`) or test mode (`false`).
    let livemode: Bool
    /// Current status of the verification attempt.
    let status: VerificationStatus?
    /// URL to which the cardholder is redirected to complete the 3DS challenge.
    let challengeURL: String
    /// Unix timestamp (seconds) when the verification was completed, if applicable.
    let completed: Int?
    /// Unix timestamp (seconds) when the verification was created.
    let created: Int
    /// Unix timestamp (seconds) when the verification was last updated.
    let updated: Int

    enum CodingKeys: String, CodingKey {
        case id, customer, object, livemode, status, completed, created, updated
        case paymentMethod = "payment_method"
        case challengeURL = "challenge_url"
    }
}

/// An error response returned by the Frame API when a 3D Secure verification request fails.
struct ThreeDSecureVerificationError: Codable {
    /// Detailed error information from the API.
    struct VerificationError: Codable {
        /// Machine-readable error type (e.g. `"invalid_request_error"`).
        let type: String
        /// Human-readable description of the error.
        let message: String
        /// Identifier of a pre-existing payment intent, if the failure is due to a duplicate.
        let existingIntentId: String?

        enum CodingKeys: String, CodingKey {
            case type, message
            case existingIntentId = "existing_intent_id"
        }
    }

    /// The error payload returned by the API.
    let error: VerificationError
}
