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
}

struct ThreeDSecureVerification: Codable {
    let id: String
    let object: String
    let customerId: String
    let paymentMethodId: String
    let status: VerificationStatus?
    let challengeURL: String
    let challengeSentAt: Int
    let challengeCompletedAt: Int?
    let expiresAt: Int
    let created: Int
    let updated: Int
    
    enum CodingKeys: String, CodingKey {
        case id, object, status, created, updated
        case customerId = "customer_id"
        case paymentMethodId = "payment_method_id"
        case challengeURL = "challenge_url"
        case challengeSentAt = "challenge_sent_at"
        case challengeCompletedAt = "challenge_completed_at"
        case expiresAt = "expires_at"
    }
}

struct ThreeDSecureVerificationError: Codable {
    struct VerificationError: Codable {
        let type: String?
        let message: String?
        let existingIntentId: String?
        
        enum CodingKeys: String, CodingKey {
            case type, message
            case existingIntentId = "existing_intent_id"
        }
    }

    let error: VerificationError?
}
