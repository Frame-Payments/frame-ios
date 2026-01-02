//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/30/25.
//

import Foundation

enum SessionStatus: String, Codable {
    case inProgress = "in_progress"
    case completed
    case failed
    case canceled
}

struct SessionComponents: Codable {
    var paymentMethod: PaymentMethodComponent?
    var identityVerification: IdentityVerificationComponent?

    enum CodingKeys: String, CodingKey {
        case paymentMethod = "payment_method"
        case identityVerification = "identity_verification"
    }
}

struct IdentityVerificationComponent: Codable {
    var enabled: Bool
    var provider: String = "persona"
}

struct PaymentMethodComponent: Codable {
    var enabled: Bool
    var requiredTypes: [String] = ["card"]
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case requiredTypes = "required_types"
    }
}

struct OnboardingSteps: Codable {
    let paymentMethodAdded: Bool
    let identityVerified: Bool
    let threeDSVerified: Bool
    let termsAccepted: Bool
    let profileCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case paymentMethodAdded = "payment_method_added"
        case identityVerified = "identity_verified"
        case threeDSVerified = "three_ds_verified"
        case termsAccepted = "terms_accepted"
        case profileCompleted = "profile_completed"
    }
}

struct OnboardingSession: Codable {
    let id: String
    let object: String
    let userId: String
    let customerId: String
    let status: SessionStatus
    let steps: OnboardingSteps
    let components: SessionComponents
    let entryPoint: String
    let metadata: [String: String]
    let clientSecret: String
    let createdAt: Int
    let updatedAt: Int
    let expiresAt: Int
    let completedAt: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case userId = "user_id"
        case customerId = "customer_id"
        case status
        case steps
        case components
        case entryPoint = "entry_point"
        case metadata
        case clientSecret = "client_secret"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
        case completedAt = "completed_at"
    }
}
