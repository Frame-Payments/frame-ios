//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/2/26.
//

import Foundation
import Frame

enum ThreeDSecureEndpoints: FrameNetworkingEndpoints {
    //MARK: Onboarding Session Endpoints
    case create3DSecureVerification
    case retrieve3DSecureVerification(verificationId: String)
    case resend3DSecureVerification(verificationId: String)
    
    var endpointURL: String {
        switch self {
        case .create3DSecureVerification:
            return "/v1/3ds/intents"
        case .retrieve3DSecureVerification(let verificationId):
            return "/v1/3ds/intents/\(verificationId)"
        case .resend3DSecureVerification(let verificationId):
            return "/v1/3ds/intents/\(verificationId)/resend"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .retrieve3DSecureVerification:
            return .GET
        default:
            return .POST
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}
