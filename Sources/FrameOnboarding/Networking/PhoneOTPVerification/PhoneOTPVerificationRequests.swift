//
//  PhoneOTPVerificationRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

class PhoneOTPVerificationRequests {
    /// Confirm with OTP code (Twilio path). Empty body for Prove path.
    struct ConfirmVerificationRequest: Encodable, Sendable {
        let code: String?

        init(code: String? = nil) {
            self.code = code
        }

        enum CodingKeys: String, CodingKey {
            case code
        }
    }

    /// Create phone verification request. dateOfBirth must be YYYY-MM-DD.
    struct CreateVerificationRequest: Encodable, Sendable {
        let type: String
        let phoneNumber: String
        let dateOfBirth: String

        init(type: String = "phone", phoneNumber: String, dateOfBirth: String) {
            self.type = type
            self.phoneNumber = phoneNumber
            self.dateOfBirth = dateOfBirth
        }

        enum CodingKeys: String, CodingKey {
            case type
            case phoneNumber = "phone_number"
            case dateOfBirth = "date_of_birth"
        }
    }
}
