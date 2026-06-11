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

    enum CodingKeys: String, CodingKey {
        case fingerprintVisitorId = "fingerprint_visitor_id"
    }
}
