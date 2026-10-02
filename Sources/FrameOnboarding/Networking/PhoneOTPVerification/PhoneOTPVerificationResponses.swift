//
//  PhoneOTPVerificationObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation
import Frame

/// Response model returned when a phone OTP verification session is created.
public struct PhoneOTPVerificationCreateResponse: Codable {
    /// Unique identifier for the verification session.
    public let id: String
    /// The type of verification session.
    public let type: String
    /// Current status of the verification session.
    public let status: String
    /// The provider handling this verification — `prove`, `twilio`, or `sandbox`.
    ///
    /// Authoritative for which path to run. The backend routes a retry to `twilio` when a
    /// recent Prove attempt on the same number never verified, so re-creating after a Prove
    /// failure is what moves the applicant onto the code-entry path.
    @Lenient public private(set) var provider: String?
    /// Prove auth token associated with the session, if available.
    @Lenient public private(set) var proveAuthToken: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status, provider
        case proveAuthToken = "prove_auth_token"
    }
}

/// Response model returned when a phone OTP verification session is confirmed.
public struct PhoneOTPVerificationConfirmResponse: Codable {
    /// Unique identifier for the verification session.
    public let id: String
    /// Current status of the confirmed verification session.
    public let status: String
    /// Status of any prefill data associated with the session, if available.
    @Lenient public private(set) var prefillStatus: String?
    /// Individual profile returned once, when `prefillStatus` is `prefilled`. A replay omits it.
    @Lenient public private(set) var profile: FrameObjects.AccountProfile?

    /// Creates a new ``PhoneOTPVerificationConfirmResponse``.
    /// - Parameters:
    ///   - id: Unique identifier for the verification session.
    ///   - status: Current status of the confirmed verification session.
    ///   - prefillStatus: Status of any prefill data associated with the session.
    ///   - profile: One-time prefill profile, present only when `prefillStatus` is `prefilled`.
    public init(id: String, status: String, prefillStatus: String? = nil, profile: FrameObjects.AccountProfile? = nil) {
        self.id = id
        self.status = status
        self.prefillStatus = prefillStatus
        self.profile = profile
    }

    enum CodingKeys: String, CodingKey {
        case id, status, profile
        case prefillStatus = "prefill_status"
    }
}
