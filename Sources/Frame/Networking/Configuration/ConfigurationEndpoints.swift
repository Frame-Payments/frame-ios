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
        }
    }
    
    var httpMethod: HTTPMethod {
        return .GET
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }

    var additionalHeaders: [String: String] {
        switch self {
        case .getFingerprintConfiguration:
            // Declares what this build can handle, not which release it is: the API
            // reads this to decide which Fingerprint environment's key to serve.
            // Saying nothing keeps the legacy key, which is what older builds get.
            return [FingerprintCapability.header: FingerprintCapability.sealed]
        default:
            return [:]
        }
    }
}
