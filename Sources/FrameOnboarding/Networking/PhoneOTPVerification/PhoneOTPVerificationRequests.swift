//
//  PhoneOTPVerificationRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

class PhoneOTPVerificationRequests {
    struct Initialize: Encodable, Sendable {
        let phoneNumber: String
        let dateOfBirth: String
        let flowType: String

        init(phoneNumber: String, dateOfBirth: String, flowType: String) {
            self.phoneNumber = phoneNumber
            self.dateOfBirth = dateOfBirth
            self.flowType = flowType
        }

        enum CodingKeys: String, CodingKey {
            case phoneNumber = "phone_number"
            case dateOfBirth = "date_of_birth"
            case flowType = "flow_type"
        }
    }

    struct Verify: Encodable, Sendable {
        let authId: String

        init(authId: String) {
            self.authId = authId
        }

        enum CodingKeys: String, CodingKey {
            case authId = "auth_id"
        }
    }
}
