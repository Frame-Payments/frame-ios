//
//  PhoneOTPVerificationEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation
import Frame

enum PhoneOTPVerificationEndpoints: FrameNetworkingEndpoints {
    case initialize
    case verify

    var endpointURL: String {
        switch self {
        case .initialize:
            return "/v1/phone-otp/initialize"
        case .verify:
            return "/v1/phone-otp/verify"
        }
    }

    var httpMethod: HTTPMethod {
        return .POST
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
