//
//  CustomerResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

public class CustomerResponses {
    public struct ListCustomersResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.Customer]?
    }
    
    public struct DeleteCustomerResponse: Codable {
        public let id: String
        public let object: String
        public let deleted: Bool
    }
}
