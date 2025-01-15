//
//  ConfigurationEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation

enum ConfigurationEndpoints: FrameNetworkingEndpoints {
    //MARK: Configuration Endpoints
    case getConfiguration
    
    var endpointURL: String {
        switch self {
        case .getConfiguration:
            return "/v1/config/evervault"
        }
    }
    
    var httpMethod: String {
        return "GET"
    }
    
    var queryItems: [URLQueryItem]? {
        return []
    }
}
