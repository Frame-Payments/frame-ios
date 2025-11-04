//
//  InvoiceObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

extension FrameObjects {
    public enum InvoiceStatus: String, Codable, Sendable {
        case draft, outstanding, due, overdue, paid, voided, open
        case writtenOff = "written_off"
    }
    
    public enum InvoiceCollectionMethod: String, Codable, Sendable {
        case autoCharge = "auto_charge"
        case requestPayment = "request_payment"
    }
    
    public struct Invoice: Codable, Sendable, Identifiable, Equatable  {
        
        public struct InvoiceLineItem: Codable, Sendable, Identifiable, Equatable {
            public let object: String?
            public let id: String?
            public let quantity: Int?
            public let product: InvoiceProduct?
        }
        
        public struct InvoiceProduct: Codable, Sendable, Identifiable, Equatable {
            public let object: String?
            public let id: String?
            public let name: String?
            public let price: Int?
        }
        
        public let id: String
        public var customer: Customer?
        public let object: String
        public let total: Int
        public let currency: String
        public var status: InvoiceStatus
        public var collectionMethod: InvoiceCollectionMethod
        public let netTerms: Int
        public let invoiceNumber: String
        public let description: String
        public let memo: String
        public let livemode: Bool
        public let metadata: [String: String]?
        public var lineItems: [InvoiceLineItem]?
        public let created: Int
        public let updated: Int
        
        init(id: String, customer: Customer?, object: String, total: Int, currency: String, status: InvoiceStatus, collectionMethod: InvoiceCollectionMethod, netTerms: Int, invoiceNumber: String, description: String, memo: String, livemode: Bool, metadata: [String : String]?, lineItems: [InvoiceLineItem]?, created: Int, updated: Int) {
            self.id = id
            self.customer = customer
            self.object = object
            self.total = total
            self.currency = currency
            self.status = status
            self.collectionMethod = collectionMethod
            self.netTerms = netTerms
            self.invoiceNumber = invoiceNumber
            self.description = description
            self.memo = memo
            self.livemode = livemode
            self.metadata = metadata
            self.lineItems = lineItems
            self.created = created
            self.updated = updated
        }
        
        public enum CodingKeys: String, CodingKey {
            case id, customer, object, total, currency, status, description, memo, livemode, metadata, created, updated
            case collectionMethod = "collection_method"
            case netTerms = "net_terms"
            case invoiceNumber = "invoice_number"
            case lineItems = "line_items"
        }
    }
}
