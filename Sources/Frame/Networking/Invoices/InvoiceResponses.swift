//
//  InvoiceResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

/// Response model namespace for Invoices API calls.
public class InvoiceResponses {
    /// Decoded response returned when listing invoices.
    public struct ListInvoicesResponse: Codable {
        /// Pagination and context metadata for the result set.
        public let meta: FrameMetadata?
        /// The array of invoices returned by the request.
        public let data: [FrameObjects.Invoice]?
    }

    /// Decoded response returned when deleting an invoice.
    public struct DeleteInvoiceResponse: Codable {
        /// The object type identifier returned by the API.
        public let object: String
        /// Indicates whether the invoice was successfully deleted.
        public let deleted: Bool
    }
}
