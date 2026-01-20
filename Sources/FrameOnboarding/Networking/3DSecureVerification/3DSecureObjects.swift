//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/2/26.
//

import Foundation

enum VerificationStatus: String, Codable {
    case pending
    case succeeded
    case failed
    case issued
}

struct ThreeDSecureVerification: Codable {
    let id: String
    let customer: String
    let paymentMethod: String
    let object: String
    let livemode: Bool
    let status: VerificationStatus?
    let challengeURL: String
    let completed: Int?
    let created: Int
    let updated: Int

    enum CodingKeys: String, CodingKey {
        case id, customer, object, livemode, status, completed, created, updated
        case paymentMethod = "payment_method"
        case challengeURL = "challenge_url"
    }
}

struct ThreeDSecureVerificationError: Codable {
    struct VerificationError: Codable {
        let type: String
        let message: String
        let existingIntentId: String?
        
        enum CodingKeys: String, CodingKey {
            case type, message
            case existingIntentId = "existing_intent_id"
        }
    }

    let error: VerificationError
}
