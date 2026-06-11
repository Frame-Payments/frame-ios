//
//  ProductObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

extension FrameObjects {
    /// A product available for purchase through the Frame SDK.
    public struct Product: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the product.
        public let id: String
        /// Display name of the product.
        public let name: String
        /// Indicates whether the product exists in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// URL of the product's image, if available.
        public let image: String?
        /// Human-readable description of the product.
        public let productDescription: String
        /// URL of the product's marketing page, if available.
        public let url: String?
        /// Indicates whether the product can be physically shipped.
        public let shippable: Bool
        /// Indicates whether the product is currently available for purchase.
        public let active: Bool
        /// The default price of the product in the smallest currency unit (e.g. cents).
        public let defaultPrice: Int
        /// Arbitrary key-value metadata attached to the product, if any.
        public let metadata: [String: String]?
        /// The API object type identifier (always `"product"`).
        public let object: String
        /// Unix timestamp of when the product was created.
        public let created: Int
        /// Unix timestamp of when the product was last updated.
        public let updated: Int

        /// Creates a new ``Product`` with all fields populated.
        /// - Parameters:
        ///   - id: Unique identifier for the product.
        ///   - name: Display name of the product.
        ///   - livemode: Whether the product is in live mode.
        ///   - image: Optional URL for the product image.
        ///   - productDescription: Human-readable description of the product.
        ///   - url: Optional URL for the product's marketing page.
        ///   - shippable: Whether the product can be physically shipped.
        ///   - active: Whether the product is currently active.
        ///   - defaultPrice: Default price in the smallest currency unit.
        ///   - metadata: Optional key-value metadata dictionary.
        ///   - object: API object type identifier.
        ///   - created: Unix timestamp of creation.
        ///   - updated: Unix timestamp of last update.
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

    /// Describes whether a product is purchased once or on a recurring basis.
    public enum ProductPurchaseType: String, Codable, Sendable {
        /// The product is purchased a single time with no ongoing billing.
        case oneTime = "one_time"
        /// The product is billed on a repeating schedule.
        case recurring
    }

    /// The billing interval for a recurring product subscription.
    public enum ProductRecurringInterval: String, Codable, Sendable {
        /// Billed once per day.
        case daily
        /// Billed once per month.
        case monthly
        /// Billed once per week.
        case weekly
        /// Billed once per year.
        case yearly
        /// Billed once every three months (quarterly).
        case everyThreeMonths = "every_3_months"
        /// Billed once every six months (semi-annually).
        case everySixMonths = "every_6_months"
    }
}
