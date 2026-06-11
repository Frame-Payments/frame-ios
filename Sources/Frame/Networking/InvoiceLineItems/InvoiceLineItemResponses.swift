//
//  InvoiceLineItemResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

/// Response model namespace for Invoice Line Items API calls.
public class InvoiceLineItemResponses {
    /// The paginated list of invoice line items returned by the List Line Items endpoint.
    public struct ListLineItemsResponse: Codable {
        /// The array of invoice line items returned by the request.
        public let data: [FrameObjects.InvoiceLineItem]?
    }

    /// The confirmation payload returned when a line item is deleted.
    public struct DeleteLineItemResponse: Codable {
        /// The object type identifier returned by the API.
        public let object: String
        /// Indicates whether the line item was successfully deleted.
        public let deleted: Bool
    }
}
