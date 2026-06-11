//
//  InvoiceRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

import Foundation

/// Request body namespace for Invoice API calls.
public class InvoiceRequests {
    /// Encodes the parameters required to create a new invoice.
    public struct CreateInvoiceRequest: Encodable {
        /// The identifier of the customer to associate with the invoice.
        let customer: String
        /// The method by which the invoice will be collected.
        let collectionMethod: FrameObjects.InvoiceCollectionMethod
        /// The number of days until the invoice is due (net-terms billing).
        var netTerms: Int?
        /// An optional human-readable invoice number.
        var number: Int?
        /// A short description of the invoice.
        var description: String?
        /// An internal memo visible only to the merchant.
        var memo: String?
        /// Arbitrary key-value pairs for storing additional structured information.
        var metadata: [String: String]?
        /// The line items to include on the invoice.
        var lineItems: [FrameObjects.Invoice.InvoiceLineItem]?

        /// Creates a new invoice request with the specified parameters.
        ///
        /// - Parameters:
        ///   - customer: The identifier of the customer to associate with the invoice.
        ///   - collectionMethod: The method by which the invoice will be collected.
        ///   - netTerms: The number of days until the invoice is due.
        ///   - number: An optional human-readable invoice number.
        ///   - description: A short description of the invoice.
        ///   - memo: An internal memo visible only to the merchant.
        ///   - metadata: Arbitrary key-value pairs for storing additional structured information.
        ///   - lineItems: The line items to include on the invoice.
        public init(customer: String, collectionMethod: FrameObjects.InvoiceCollectionMethod, netTerms: Int? = nil, number: Int? = nil, description: String? = nil, memo: String? = nil, metadata: [String : String]? = nil, lineItems: [FrameObjects.Invoice.InvoiceLineItem]? = nil) {
            self.customer = customer
            self.collectionMethod = collectionMethod
            self.netTerms = netTerms
            self.number = number
            self.description = description
            self.memo = memo
            self.metadata = metadata
            self.lineItems = lineItems
        }

        enum CodingKeys: String, CodingKey {
            case customer, number, description, memo, metadata
            case collectionMethod = "collection_method"
            case netTerms = "net_terms"
            case lineItems = "line_items"
        }
    }

    /// Encodes the parameters that may be updated on an existing invoice.
    public struct UpdateInvoiceRequest: Encodable {
        /// The updated collection method for the invoice.
        var collectionMethod: FrameObjects.InvoiceCollectionMethod?
        /// The updated number of days until the invoice is due.
        var netTerms: Int?
        /// An updated human-readable invoice number.
        var number: Int?
        /// An updated short description of the invoice.
        var description: String?
        /// An updated internal memo visible only to the merchant.
        var memo: String?
        /// Updated arbitrary key-value pairs for storing additional structured information.
        var metadata: [String: String]?
        /// Updated line items to include on the invoice.
        var lineItems: [FrameObjects.Invoice.InvoiceLineItem]?

        /// Creates an update invoice request; all parameters are optional and only provided fields are changed.
        ///
        /// - Parameters:
        ///   - collectionMethod: The updated collection method for the invoice.
        ///   - netTerms: The updated number of days until the invoice is due.
        ///   - number: An updated human-readable invoice number.
        ///   - description: An updated short description of the invoice.
        ///   - memo: An updated internal memo visible only to the merchant.
        ///   - metadata: Updated arbitrary key-value pairs for storing additional structured information.
        ///   - lineItems: Updated line items to include on the invoice.
        public init(collectionMethod: FrameObjects.InvoiceCollectionMethod? = nil, netTerms: Int? = nil, number: Int? = nil, description: String? = nil, memo: String? = nil, metadata: [String : String]? = nil, lineItems: [FrameObjects.Invoice.InvoiceLineItem]? = nil) {
            self.collectionMethod = collectionMethod
            self.netTerms = netTerms
            self.number = number
            self.description = description
            self.memo = memo
            self.metadata = metadata
            self.lineItems = lineItems
        }

        enum CodingKeys: String, CodingKey {
            case number, description, memo, metadata
            case collectionMethod = "collection_method"
            case netTerms = "net_terms"
            case lineItems = "line_items"
        }
    }
}
