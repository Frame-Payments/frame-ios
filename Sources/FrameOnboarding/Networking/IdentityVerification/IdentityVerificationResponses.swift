//
//  IdentityVerificationResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation
import Frame

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
    /// Whether the individual holds a satisfying identity document. `nil` means not verified.
    /// The server counts manual review as satisfying, so `true` means "may proceed", not "approved".
    @Lenient public private(set) var verified: Bool?

    /// The document check's own status. The fallback when ``category`` is nil: `declined` and
    /// `failed` are terminal for this document.
    @Lenient public private(set) var status: String?

    /// Why the KYC run did not pass. Describes the run, not this document check, so it is nil
    /// until that run concludes and nil once a document answered the step-up it asked for.
    @Lenient public private(set) var failureType: String?

    /// What the applicant should do next. Branch on this rather than ``failureType``.
    @Lenient public private(set) var category: String?

    /// Whether retrying as-is can succeed. A `step_up` is not retriable — documents are the path.
    @Lenient public private(set) var retriable: Bool?

    /// Creates a new ``IDVCompleteResponse``.
    public init(verified: Bool?,
                status: String? = nil,
                failureType: String? = nil,
                category: String? = nil,
                retriable: Bool? = nil) {
        self.verified = verified
        self.status = status
        self.failureType = failureType
        self.category = category
        self.retriable = retriable
    }

    enum CodingKeys: String, CodingKey {
        case verified, status, category, retriable
        case failureType = "failure_type"
    }
}
