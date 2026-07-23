//
//  IdentityVerificationRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

class IdentityVerificationRequests {
    /// Confirm a completed Persona inquiry (`POST /idv/complete`).
    struct CompleteRequest: Encodable, Sendable {
        let inquiryId: String

        init(inquiryId: String) {
            self.inquiryId = inquiryId
        }

        enum CodingKeys: String, CodingKey {
            case inquiryId = "inquiry_id"
        }
    }
}
