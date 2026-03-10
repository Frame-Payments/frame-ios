//
//  PhoneOTPVerificationObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

public struct PhoneOTPVerificationCreateResponse: Codable {
    public let id: String
    public let type: String
    public let status: String
    public let proveAuthToken: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status
        case proveAuthToken = "prove_auth_token"
    }
}

public struct PhoneOTPVerificationConfirmResponse: Codable {
    public let id: String
    public let status: String
    public let prefillStatus: String?

    public init(id: String, status: String, prefillStatus: String? = nil) {
        self.id = id
        self.status = status
        self.prefillStatus = prefillStatus
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case prefillStatus = "prefill_status"
    }
}
