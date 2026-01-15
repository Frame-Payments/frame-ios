//
//  ConfigurationEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation

enum ConfigurationEndpoints: FrameNetworkingEndpoints {
    //MARK: Configuration Endpoints
    case getEvervaultConfiguration
    case getSiftConfiguration
    
    var endpointURL: String {
        switch self {
        case .getEvervaultConfiguration:
            return "/v1/config/evervault"
        case .getSiftConfiguration:
            return "/v1/config/sift"
        }
    }
    
    var httpMethod: HTTPMethod {
        return .GET
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}
