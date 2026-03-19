//
//  TermsOfServiceRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/19/26.
//

import Foundation

public class TermsOfServiceRequest {
    public struct UpdateRequest: Codable {
        public let token: String
        public let acceptedAt: Int?
        public let ipAddress: String?
        public let userAgent: String?

        public init(token: String, acceptedAt: Int? = nil, ipAddress: String? = nil, userAgent: String? = nil) {
            self.token = token
            self.acceptedAt = acceptedAt
            self.ipAddress = ipAddress
            self.userAgent = userAgent
        }

        enum CodingKeys: String, CodingKey {
            case token
            case acceptedAt = "accepted_at"
            case ipAddress = "ip_address"
            case userAgent = "user_agent"
        }
    }
}
