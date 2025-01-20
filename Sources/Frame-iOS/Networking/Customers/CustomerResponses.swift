//
//  CustomerResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

public class CustomerResponses {
    struct ListCustomersResponse: Codable {
        let meta: FrameMetadata?
        let data: [FrameObjects.Customer]?
        
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
