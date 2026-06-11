//
//  TermsOfServiceObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/19/26.
//

import Foundation

extension FrameObjects {
    /// The response object returned when fetching a Terms of Service acceptance token.
    public struct TermsOfServiceTokenResponse: Codable, Sendable {
        /// The token representing a user's acceptance of the Terms of Service.
        public let token: String
    }
}
