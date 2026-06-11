//
//  InvoiceObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

extension FrameObjects {
    /// Represents the lifecycle state of an invoice.
    public enum InvoiceStatus: String, Codable, Sendable {
        /// The invoice has been created but not yet finalized or sent.
        case draft
        /// The invoice has been sent and is awaiting payment.
        case outstanding
        /// The invoice payment is currently due.
        case due
        /// The invoice payment is past its due date.
        case overdue
        /// The invoice has been fully paid.
        case paid
        /// The invoice has been voided and is no longer collectible.
        case voided
        /// The invoice is open and active.
        case open
        /// The invoice balance has been written off as uncollectible.
        case writtenOff = "written_off"
    }

    /// Describes how payment is collected for an invoice.
    public enum InvoiceCollectionMethod: String, Codable, Sendable {
        /// Payment is automatically charged to the customer's default payment method.
        case autoCharge = "auto_charge"
        /// The customer is sent a payment request and pays manually.
        case requestPayment = "request_payment"
    }

    /// A Frame invoice representing a bill sent to a customer for goods or services.
    public struct Invoice: Codable, Sendable, Identifiable, Equatable {

        /// A single line item on an invoice, representing a quantity of a product.
        public struct InvoiceLineItem: Codable, Sendable, Identifiable, Equatable {
            /// The API object type identifier for this line item.
            public let object: String?
            /// The unique identifier for this line item.
            public let id: String?
            /// The number of units of the product included in this line item.
            public let quantity: Int?
            /// The product associated with this line item.
            public let product: InvoiceProduct?
        }

        /// A product referenced by an invoice line item.
        public struct InvoiceProduct: Codable, Sendable, Identifiable, Equatable {
            /// The API object type identifier for this product.
            public let object: String?
            /// The unique identifier for this product.
            public let id: String?
            /// The human-readable name of the product.
            public let name: String?
            /// The unit price of the product in the smallest currency unit (e.g., cents).
            public let price: Int?
        }

        /// The unique identifier for this invoice.
        public let id: String
        /// The customer to whom this invoice is addressed.
        public var customer: Customer?
        /// The API object type identifier for this invoice.
        public let object: String
        /// The total amount due in the smallest currency unit (e.g., cents).
        public let total: Int
        /// The three-letter ISO 4217 currency code for the invoice amount.
        public let currency: String
        /// The current lifecycle status of the invoice.
        public var status: InvoiceStatus
        /// The method used to collect payment for this invoice.
        public var collectionMethod: InvoiceCollectionMethod
        /// The number of days from issuance until the invoice is due (net terms).
        public let netTerms: Int
        /// The human-readable invoice reference number.
        public let invoiceNumber: String
        /// A short description summarizing the purpose of the invoice.
        public let description: String
        /// An optional memo or note included on the invoice.
        public let memo: String
        /// Indicates whether this invoice was created in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// Arbitrary key-value pairs for storing additional structured information on the invoice.
        public let metadata: [String: String]?
        /// The line items that make up the invoice.
        public var lineItems: [InvoiceLineItem]?
        /// The Unix timestamp (seconds) at which the invoice was created.
        public let created: Int
        /// The Unix timestamp (seconds) at which the invoice was last updated.
        public let updated: Int

        /// Creates a new ``Invoice`` with all fields explicitly provided.
        /// - Parameters:
        ///   - id: The unique identifier for the invoice.
        ///   - customer: The customer to whom the invoice is addressed.
        ///   - object: The API object type identifier.
        ///   - total: The total amount due in the smallest currency unit.
        ///   - currency: The three-letter ISO 4217 currency code.
        ///   - status: The current lifecycle status of the invoice.
        ///   - collectionMethod: The method used to collect payment.
        ///   - netTerms: The number of days until the invoice is due.
        ///   - invoiceNumber: The human-readable invoice reference number.
        ///   - description: A short description of the invoice.
        ///   - memo: An optional memo included on the invoice.
        ///   - livemode: Whether the invoice belongs to live mode.
        ///   - metadata: Arbitrary key-value metadata attached to the invoice.
        ///   - lineItems: The line items that make up the invoice.
        ///   - created: Unix timestamp of when the invoice was created.
        ///   - updated: Unix timestamp of when the invoice was last updated.
        public init(id: String, customer: Customer?, object: String, total: Int, currency: String, status: InvoiceStatus, collectionMethod: InvoiceCollectionMethod, netTerms: Int, invoiceNumber: String, description: String, memo: String, livemode: Bool, metadata: [String : String]?, lineItems: [InvoiceLineItem]?, created: Int, updated: Int) {
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

        enum CodingKeys: String, CodingKey {
            case id, customer, object, total, currency, status, description, memo, livemode, metadata, created, updated
            case collectionMethod = "collection_method"
            case netTerms = "net_terms"
            case invoiceNumber = "invoice_number"
            case lineItems = "line_items"
        }
    }
}
