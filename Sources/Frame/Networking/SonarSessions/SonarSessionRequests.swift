//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

public typealias SessionId = String

public struct SessionResponse: Decodable {
    let sonarSessionId: String
    
    enum CodingKeys: String, CodingKey {
        case sonarSessionId = "sonar_session_id"
    }
}

public struct SessionRequestBody: Encodable {
    let fingerprintVisitorId: String
    
    enum CodingKeys: String, CodingKey {
        case fingerprintVisitorId = "fingerprint_visitor_id"
    }
}
