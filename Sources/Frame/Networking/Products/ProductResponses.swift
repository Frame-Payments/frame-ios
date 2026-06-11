//
//  ProductResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

/// Response model namespace for Products API calls.
public class ProductResponses {
    /// Paginated response returned when listing all products.
    public struct ListProductsResponse: Codable {
        /// Pagination and request metadata.
        public let meta: FrameMetadata?
        /// The array of products returned by the request.
        public let data: [FrameObjects.Product]?
    }

    /// Response returned when searching for products by query.
    public struct SearchProductResponse: Codable {
        /// Pagination and request metadata.
        public let meta: FrameMetadata?
        /// The array of products matching the search criteria.
        public let products: [FrameObjects.Product]?
    }

    /// Response returned when a product is successfully deleted.
    public struct DeleteProductResponse: Codable {
        /// The unique identifier of the deleted product.
        public let id: String
        /// The object type, typically `"product"`.
        public let object: String
        /// Indicates whether the product was deleted successfully.
        public let deleted: Bool
    }
}
