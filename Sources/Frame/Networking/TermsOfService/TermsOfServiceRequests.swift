//
//  TermsOfServiceRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/19/26.
//

import Foundation

/// Request body namespace for Terms of Service API calls.
public class TermsOfServiceRequest {
    /// Request body for updating a Terms of Service acceptance record.
    public struct UpdateRequest: Codable {
        /// The Terms of Service token identifying the specific agreement version.
        public let token: String
        /// Unix timestamp (seconds) at which the user accepted the Terms of Service.
        public let acceptedAt: Int?
        /// IP address of the user at the time of acceptance.
        public let ipAddress: String?
        /// User-agent string of the browser or client at the time of acceptance.
        public let userAgent: String?

        /// Creates a new ``UpdateRequest``.
        /// - Parameters:
        ///   - token: The Terms of Service token identifying the agreement version.
        ///   - acceptedAt: Unix timestamp of acceptance; pass `nil` to omit.
        ///   - ipAddress: IP address of the accepting client; pass `nil` to omit.
        ///   - userAgent: User-agent string of the accepting client; pass `nil` to omit.
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
