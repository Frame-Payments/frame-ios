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
    let fingerprintVisitorId: String

    /// The Frame account the session belongs to.
    ///
    /// Required for any session that will back a payment: the server resolves a payment's session
    /// through the account, so one created without this is invisible to risk checks and the payment
    /// is rejected with `sonar_session_required`.
    let accountId: String?

    init(fingerprintVisitorId: String, accountId: String? = nil) {
        self.fingerprintVisitorId = fingerprintVisitorId
        self.accountId = accountId
    }

    enum CodingKeys: String, CodingKey {
        case fingerprintVisitorId = "fingerprint_visitor_id"
        case accountId = "account_id"
    }
}
