//
//  DeviceAttestationEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/14/26.
//

import Foundation

enum DeviceAttestationEndpoints: FrameNetworkingEndpoints {
    case challenge
    case attest

    var endpointURL: String {
        switch self {
        case .challenge:
            return "/v1/client/device_attestation/challenge"
        case .attest:
            return "/v1/client/device_attestation/attest"
        }
    }

    var httpMethod: HTTPMethod {
        return .POST
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
