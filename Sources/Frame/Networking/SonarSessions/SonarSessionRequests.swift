//
//  File.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 3/2/26.
//

import Foundation

public typealias SessionId = String

public struct SessionResponse: Decodable {
    let sonar_session_id: String
}

public struct SessionRequestBody: Encodable {
    let fingerprint_visitor_id: String
}
