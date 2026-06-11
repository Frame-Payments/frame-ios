//
//  ProductPhasesResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation

/// Response model namespace for Product Phases API calls.
public class ProductPhasesResponses {
    /// The decoded response returned when listing subscription phases for a product.
    public struct ListProductPhasesResponse: Codable {
        /// Metadata associated with the list response, such as the owning product identifier.
        public let meta: ProductPhaseMeta?
        /// The collection of subscription phases returned by the API.
        public let phases: [FrameObjects.SubscriptionPhase]?
    }

    /// Metadata included in a product-phases list response.
    public struct ProductPhaseMeta: Codable {
        /// The unique identifier of the product that owns these phases.
        public let productId: String?

        /// Maps Swift property names to their JSON snake_case keys.
        public enum CodingKeys: String, CodingKey {
            /// Maps `productId` to the `"product_id"` JSON key.
            case productId = "product_id"
        }
    }
}
