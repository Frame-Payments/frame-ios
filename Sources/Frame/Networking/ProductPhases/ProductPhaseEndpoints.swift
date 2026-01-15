//
//  ProductPhaseEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation

enum ProductPhaseEndpoints: FrameNetworkingEndpoints {
    //MARK: Product Endpoints
    case createProductPhase(productId: String)
    case updateProductPhaseWith(productId: String, phaseId: String)
    case getAllProductPhases(productId: String)
    case getProductPhaseWith(productId: String, phaseId: String)
    case deleteProductPhase(productId: String, phaseId: String)
    case bulkUpdateProductPhases(productId: String)
    
    var endpointURL: String {
        switch self {
        case .createProductPhase(let productId), .getAllProductPhases(let productId):
            return "/v1/products/\(productId)/phases"
        case .getProductPhaseWith(let productId, let phaseId), .updateProductPhaseWith(let productId, let phaseId), .deleteProductPhase(let productId, let phaseId):
            return "/v1/products/\(productId)/phases/\(phaseId)"
        case .bulkUpdateProductPhases(let productId):
            return "/v1/products/\(productId)/phases/bulk_update"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .createProductPhase:
            return .POST
        case .updateProductPhaseWith, .bulkUpdateProductPhases:
            return .PATCH
        case .deleteProductPhase:
            return .DELETE
        default:
            return .GET
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}
