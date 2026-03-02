//
//  GeocomplianceEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation
import Frame

enum GeocomplianceEndpoints: FrameNetworkingEndpoints {
    case listGeofences
    case accountGeoCompliance(accountId: String)

    var endpointURL: String {
        switch self {
        case .listGeofences:
            return "/v1/geofences"
        case .accountGeoCompliance(let accountId):
            return "/v1/accounts/\(accountId)/geo_compliance"
        }
    }

    var httpMethod: HTTPMethod {
        return .GET
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}

