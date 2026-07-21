//
//  IdentityVerificationResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

/// Response model returned when an IDV session is created (`POST /idv/session`).
///
/// The server pre-fills and creates the Persona inquiry, returning its identifier so the
/// client can launch the Persona SDK against the existing inquiry.
public struct IDVSessionResponse: Codable, Sendable {
    /// The pre-created Persona inquiry identifier (`inq_…`) to launch the SDK against.
    public let inquiryId: String

    /// Creates a new ``IDVSessionResponse``.
    /// - Parameter inquiryId: The pre-created Persona inquiry identifier (`inq_…`).
    public init(inquiryId: String) {
        self.inquiryId = inquiryId
    }

    enum CodingKeys: String, CodingKey {
        case inquiryId = "inquiry_id"
    }
}

/// Response model returned when an IDV inquiry is completed (`POST /idv/complete`, JSON variant).
///
/// This server response is the source of truth for whether identity verification succeeded —
/// the Persona client-side `onComplete`/`status` callbacks are best-effort and must not be
/// trusted to flip the UI to verified.
public struct IDVCompleteResponse: Codable, Sendable {
    /// Whether the identity verification passed server-side review.
    public let verified: Bool

    /// Creates a new ``IDVCompleteResponse``.
    /// - Parameter verified: Whether the identity verification passed server-side review.
    public init(verified: Bool) {
        self.verified = verified
    }

    enum CodingKeys: String, CodingKey {
        case verified
    }
}
