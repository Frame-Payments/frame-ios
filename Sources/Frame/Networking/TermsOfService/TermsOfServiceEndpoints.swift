//
//  TermsOfServiceEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/19/26.
//

import Foundation

enum TermsOfServiceEndpoints: FrameNetworkingEndpoints {
    case createToken
    case update

    var endpointURL: String {
        return "/v1/terms_of_service"
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .createToken:
            return .POST
        case .update:
            return .PATCH
        }
    }

    var queryItems: [URLQueryItem]? { nil }
}
