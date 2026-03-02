//
//  File.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 3/2/26.
//

import Foundation

public enum SonarSessionEndpoints: FrameNetworkingEndpoints {
    case create
    case update(id: String)
    
    var endpointURL: String {
        switch self {
        case .create:
            return "/v1/charge_sessions"
        case .update(let id):
            return "/v1/charge_sessions/\(id)"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .create:
            return .POST
        case .update:
            return .PUT
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
}
