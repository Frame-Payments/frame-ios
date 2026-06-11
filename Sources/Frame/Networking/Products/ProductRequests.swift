//
//  ProductRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

/// Request body namespace for Products API calls.
public class ProductRequests {
    /// Request body for creating a new product.
    public struct CreateProductRequest: Codable {
        /// The display name of the product.
        let name: String
        /// A human-readable description of the product.
        let description: String
        /// The default price for the product, expressed in the smallest currency unit (e.g. cents).
        let defaultPrice: Int
        /// Whether the product is sold as a one-time purchase or a recurring subscription.
        let purchaseType: FrameObjects.ProductPurchaseType
        /// The billing interval for recurring products. Required when `purchaseType` is `.recurring`.
        var recurringInterval: FrameObjects.ProductRecurringInterval? // Required if Purchase Type is RECURRING
        /// Whether the product requires physical shipment.
        var shippable: Bool?
        /// An optional URL associated with the product (e.g. a product detail page).
        var url: String?
        /// Arbitrary key-value metadata to attach to the product.
        var metadata: [String: String]?

        /// Creates a new `CreateProductRequest`.
        ///
        /// - Parameters:
        ///   - name: The display name of the product.
        ///   - description: A human-readable description of the product.
        ///   - defaultPrice: The default price in the smallest currency unit (e.g. cents).
        ///   - purchaseType: Whether the product is one-time or recurring.
        ///   - recurringInterval: The billing interval; required when `purchaseType` is `.recurring`.
        ///   - shippable: Whether the product requires physical shipment.
        ///   - url: An optional URL associated with the product.
        ///   - metadata: Arbitrary key-value metadata to attach to the product.
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

    /// Request body for updating an existing product.
    public struct UpdateProductRequest: Codable {
        /// The updated display name of the product.
        let name: String
        /// The updated human-readable description of the product.
        let description: String
        /// The updated default price in the smallest currency unit (e.g. cents).
        let defaultPrice: Int
        /// Whether the product requires physical shipment.
        var shippable: Bool?
        /// An optional URL associated with the product (e.g. a product detail page).
        var url: String?
        /// Arbitrary key-value metadata to attach to the product.
        var metadata: [String: String]?

        /// Creates a new `UpdateProductRequest`.
        ///
        /// - Parameters:
        ///   - name: The updated display name of the product.
        ///   - description: The updated human-readable description of the product.
        ///   - defaultPrice: The updated default price in the smallest currency unit (e.g. cents).
        ///   - shippable: Whether the product requires physical shipment.
        ///   - url: An optional URL associated with the product.
        ///   - metadata: Arbitrary key-value metadata to attach to the product.
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
