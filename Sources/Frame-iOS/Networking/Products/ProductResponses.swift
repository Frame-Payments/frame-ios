//
//  ProductResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

public class ProductResponses {
    public struct ListProductsResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.Product]?
    }
    
    public struct SearchProductResponse: Codable {
        public let meta: FrameMetadata?
        public let products: [FrameObjects.Product]?
    }
    
    public struct DeleteProductResponse: Codable {
        public let id: String
        public let object: String
        public let deleted: Bool
    }
}
