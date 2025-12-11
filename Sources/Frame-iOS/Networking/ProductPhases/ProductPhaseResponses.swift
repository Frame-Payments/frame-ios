//
//  ProductPhasesResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation

public class ProductPhasesResponses {
    public struct ListProductPhasesResponse: Codable {
        public let meta: ProductPhaseMeta?
        public let phases: [FrameObjects.SubscriptionPhase]?
    }
    
    public struct ProductPhaseMeta: Codable {
        public let productId: String?
        
        public enum CodingKeys: String, CodingKey {
            case productId = "product_id"
        }
    }
}
