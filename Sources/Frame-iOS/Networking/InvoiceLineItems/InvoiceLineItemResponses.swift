//
//  InvoiceLineItemResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

public class InvoiceLineItemResponses {
    public struct ListLineItemsResponse: Codable {
        public let data: [FrameObjects.InvoiceLineItem]?
    }
    
    public struct DeleteLineItemResponse: Codable {
        public let object: String
        public let deleted: Bool
    }
}
