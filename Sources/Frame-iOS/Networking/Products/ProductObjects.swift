//
//  ProductObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

extension FrameObjects {
    public struct Product: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let name: String
        public let livemode: Bool
        public let image: String?
        public let productDescription: String
        public let url: String?
        public let shippable: Bool
        public let active: Bool
        public let defaultPrice: Int
        public let metadata: [String: String]?
        public let object: String
        public let created: Int
        public let updated: Int
        
        public init(id: String, name: String, livemode: Bool, image: String?, productDescription: String, url: String?, shippable: Bool, active: Bool, defaultPrice: Int, metadata: [String : String]?, object: String, created: Int, updated: Int) {
            self.id = id
            self.name = name
            self.livemode = livemode
            self.image = image
            self.productDescription = productDescription
            self.url = url
            self.shippable = shippable
            self.active = active
            self.defaultPrice = defaultPrice
            self.metadata = metadata
            self.object = object
            self.created = created
            self.updated = updated
        }
        
        public enum CodingKeys: String, CodingKey {
            case id, name, livemode, image, url, shippable, active, metadata, object, created, updated
            case defaultPrice = "default_price"
            case productDescription = "description"
        }
    }
    
    public enum ProductPurchaseType: String, Codable, Sendable {
        case oneTime = "one_time"
        case recurring
    }
    
    public enum ProductRecurringInterval: String, Codable, Sendable {
        case daily, monthly, weekly, yearly
        case everyThreeMonths = "every_3_months"
        case everySixMonths = "every_6_months"
    }
}
