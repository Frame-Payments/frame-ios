//
//  CustomerResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

public class CustomerResponses {
    struct ListCustomersResponse: Decodable {
        let meta: FrameMetadata?
        let data: [FrameObjects.Customer]?
    }
    
    public struct DeleteCustomerResponse: Decodable {
        let id: String?
        let object: String?
        let deleted: Bool?
    }
}
