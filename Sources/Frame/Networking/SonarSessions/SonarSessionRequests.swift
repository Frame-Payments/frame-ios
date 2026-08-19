//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

/// A type alias representing a Sonar session identifier string.
public typealias SessionId = String

/// Response model namespace for Sonar Session API calls.
public struct SessionResponse: Decodable {
    /// The unique identifier assigned to the Sonar session by the server.
    let sonarSessionId: String

    enum CodingKeys: String, CodingKey {
        case sonarSessionId = "sonar_session_id"
    }
}

/// Request body namespace for Sonar Session API calls.
public struct SessionRequestBody: Encodable {
    /// The Fingerprint visitor identifier used to associate the session with a device fingerprint.
    ///
    /// Empty once the Fingerprint environment is activated and withholds it, at which
    /// point ``sealedResult`` is what identifies the device.
    let fingerprintVisitorId: String

    /// The Frame account the session belongs to.
    ///
    /// Required for any session that will back a payment: the server resolves a payment's session
    /// through the account, so one created without this is invisible to risk checks and the payment
    /// is rejected with `sonar_session_required`.
    let accountId: String?

    /// The sealed Fingerprint identification event, base64-encoded.
    ///
    /// Sent alongside the visitor id rather than instead of it, so the request works
    /// on both sides of the sealed environment being activated. Omitted entirely
    /// when Fingerprint served no sealed result, which leaves the server on the
    /// legacy path it uses today.
    let sealedResult: String?

    init(fingerprintVisitorId: String, accountId: String? = nil, sealedResult: String? = nil) {
        self.fingerprintVisitorId = fingerprintVisitorId
        self.accountId = accountId
        self.sealedResult = sealedResult
    }

    /// Creates a body from a Fingerprint identification.
    init(identification: FingerprintIdentification, accountId: String? = nil) {
        self.init(fingerprintVisitorId: identification.visitorId,
                  accountId: accountId,
                  sealedResult: identification.sealedResult)
    }

    /// Encodes the body, leaving absent fields out rather than sending them as null.
    ///
    /// Written by hand because the synthesised encoder emits `null` for a nil
    /// optional, and a `sealed_result: null` is not the same request to the API as
    /// one that omits it.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fingerprintVisitorId, forKey: .fingerprintVisitorId)
        try container.encodeIfPresent(accountId, forKey: .accountId)
        try container.encodeIfPresent(sealedResult, forKey: .sealedResult)
    }

    enum CodingKeys: String, CodingKey {
        case fingerprintVisitorId = "fingerprint_visitor_id"
        case accountId = "account_id"
        case sealedResult = "sealed_result"
    }
}
