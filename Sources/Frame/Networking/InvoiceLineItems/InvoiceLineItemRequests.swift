//
//  InvoiceLineItemRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

/// Request body namespace for Invoice Line Item API calls.
public class InvoiceLineItemRequests {
    /// Request body used when creating a new invoice line item.
    public struct CreateLineItemRequest: Encodable {
        /// The identifier of the product associated with this line item.
        let product: String
        /// The quantity of the product for this line item.
        let quantity: Int
    }

    /// Request body used when updating an existing invoice line item.
    public struct UpdateLineItemRequest: Encodable {
        /// The updated product identifier, or `nil` to leave unchanged.
        var product: String?
        /// The updated quantity, or `nil` to leave unchanged.
        var quantity: Int?

        /// Creates an update request with optional field overrides.
        /// - Parameters:
        ///   - product: The updated product identifier, or `nil` to leave unchanged.
        ///   - quantity: The updated quantity, or `nil` to leave unchanged.
        public init(product: String? = nil, quantity: Int? = nil) {
            self.product = product
            self.quantity = quantity
        }
    }
}
