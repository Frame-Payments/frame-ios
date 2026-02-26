//
//  PhoneOTPVerificationEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation
import Frame

enum PhoneOTPVerificationEndpoints: FrameNetworkingEndpoints {
    case create(accountId: String)
    case confirm(accountId: String, verificationId: String)

    var endpointURL: String {
        switch self {
        case .create(let accountId):
            return "/v1/accounts/\(accountId)/phone_verifications"
        case .confirm(let accountId, let verificationId):
            return "/v1/accounts/\(accountId)/phone_verifications/\(verificationId)/confirm"
        }
    }

    var httpMethod: HTTPMethod {
        return .POST
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
