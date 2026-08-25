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
    case getFingerprintConfiguration
    case getSiftConfiguration
    case getLegalConfiguration
    case getMapboxConfiguration

    var endpointURL: String {
        switch self {
        case .getEvervaultConfiguration:
            return "/v1/config/evervault"
        case .getFingerprintConfiguration:
            return "/v1/config/fingerprint"
        case .getSiftConfiguration:
            return "/v1/config/sift"
        case .getLegalConfiguration:
            return "/v1/config/legal"
        case .getMapboxConfiguration:
            return "/v1/config/mapbox"
        }
    }
    
    var httpMethod: HTTPMethod {
        return .GET
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}
