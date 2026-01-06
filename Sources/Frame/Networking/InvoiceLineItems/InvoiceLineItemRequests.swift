//
//  InvoiceLineItemRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

public class InvoiceLineItemRequests {
    public struct CreateLineItemRequest: Encodable {
        let product: String
        let quantity: Int
    }
    
    public struct UpdateLineItemRequest: Encodable {
        var product: String?
        var quantity: Int?
        
        public init(product: String? = nil, quantity: Int? = nil) {
            self.product = product
            self.quantity = quantity
        }
    }
}
