//
//  ProductRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

public class ProductRequests {
    public struct CreateProductRequest: Codable {
        let name: String
        let description: String
        let defaultPrice: Int
        let purchaseType: FrameObjects.ProductPurchaseType
        var recurringInterval: FrameObjects.ProductRecurringInterval? // Required if Purchase Type is RECURRING
        var shippable: Bool?
        var url: String?
        var metadata: [String: String]?
        
        init(name: String, description: String, defaultPrice: Int, purchaseType: FrameObjects.ProductPurchaseType, recurringInterval: FrameObjects.ProductRecurringInterval? = nil, shippable: Bool? = nil, url: String? = nil, metadata: [String : String]? = nil) {
            self.name = name
            self.description = description
            self.defaultPrice = defaultPrice
            self.purchaseType = purchaseType
            self.recurringInterval = recurringInterval
            self.shippable = shippable
            self.url = url
            self.metadata = metadata
        }
        
        enum CodingKeys: String, CodingKey {
            case name, description, shippable, url, metadata
            case defaultPrice = "default_price"
            case purchaseType = "purchase_type"
            case recurringInterval = "recurring_interval"
        }
    }
    
    public struct UpdateProductRequest: Codable {
        let name: String
        let description: String
        let defaultPrice: Int
        var shippable: Bool?
        var url: String?
        var metadata: [String: String]?
        
        init(name: String, description: String, defaultPrice: Int, shippable: Bool? = nil, url: String? = nil, metadata: [String : String]? = nil) {
            self.name = name
            self.description = description
            self.defaultPrice = defaultPrice
            self.shippable = shippable
            self.url = url
            self.metadata = metadata
        }
        
        enum CodingKeys: String, CodingKey {
            case name, description, shippable, url, metadata
            case defaultPrice = "default_price"
        }
    }
}
