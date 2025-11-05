//
//  InvoiceRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

import Foundation

public class InvoiceRequests {
    public struct CreateInvoiceRequest: Encodable {
        let customer: String
        let collectionMethod: FrameObjects.InvoiceCollectionMethod
        var netTerms: Int?
        var number: Int?
        var description: String?
        var memo: String?
        var metadata: [String: String]?
        var lineItems: [FrameObjects.Invoice.InvoiceLineItem]?
        
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
    
    public struct UpdateInvoiceRequest: Encodable {
        var collectionMethod: FrameObjects.InvoiceCollectionMethod?
        var netTerms: Int?
        var number: Int?
        var description: String?
        var memo: String?
        var metadata: [String: String]?
        var lineItems: [FrameObjects.Invoice.InvoiceLineItem]?
        
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
