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
    case getAllConfiguration

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
        case .getAllConfiguration:
            return "/v1/config/all"
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
        case .getFingerprintConfiguration, .getAllConfiguration:
            // Declares what this build can handle, not which release it is: the API
            // reads this to decide which Fingerprint environment's key to serve.
            // Saying nothing keeps the legacy key, which is what older builds get.
            //
            // The aggregate endpoint carries it too: it is the only config request a
            // normal launch makes, and its cached fingerprint block is what every
            // later `getFingerprintConfiguration()` serves. Without the header here
            // the whole process runs on a legacy key and never asks for a sealed one.
            return [FingerprintCapability.header: FingerprintCapability.sealed]
        default:
            return [:]
        }
    }
}
