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
        
        init(meta: FrameMetadata? = nil, data: [FrameObjects.Customer]?) {
            self.meta = meta
            self.data = data
        }
    }
    
    public struct DeleteCustomerResponse: Codable {
        let id: String?
        let object: String?
        let deleted: Bool?
    }
}
