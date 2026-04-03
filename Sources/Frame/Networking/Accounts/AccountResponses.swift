//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

public class AccountResponses {
    public struct ListAccountsResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.Account]?
    }

    public struct PlaidLinkTokenResponse: Codable {
        public let linkToken: String

        enum CodingKeys: String, CodingKey {
            case linkToken = "link_token"
        }
    }
}
