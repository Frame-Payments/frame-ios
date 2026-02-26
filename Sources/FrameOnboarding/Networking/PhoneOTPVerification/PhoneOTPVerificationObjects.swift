//
//  PhoneOTPVerificationObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

struct PhoneOTPVerificationInitializeResponse: Codable {
    let authToken: String

    enum CodingKeys: String, CodingKey {
        case authToken = "auth_token"
    }
}

struct PhoneOTPVerificationVerifyResponse: Codable {
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct PhoneOTPVerificationError: Codable {
    struct ErrorDetail: Codable {
        let type: String?
        let message: String?
    }

    let error: ErrorDetail?
}
