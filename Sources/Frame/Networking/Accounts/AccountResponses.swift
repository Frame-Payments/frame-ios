//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

/// Response model namespace for Accounts API calls.
public class AccountResponses {
    /// Paginated response returned when listing accounts.
    public struct ListAccountsResponse: Codable {
        /// Pagination and request metadata for the response.
        public let meta: FrameMetadata?
        /// The array of accounts returned by the request.
        public let data: [FrameObjects.Account]?
    }

    /// Response returned when creating a Plaid Link token.
    public struct PlaidLinkTokenResponse: Codable {
        /// The Plaid Link token used to initialise the Plaid Link flow.
        public let linkToken: String

        enum CodingKeys: String, CodingKey {
            case linkToken = "link_token"
        }
    }
}
