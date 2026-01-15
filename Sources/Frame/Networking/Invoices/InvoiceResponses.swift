//
//  InvoiceResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

public class InvoiceResponses {
    public struct ListInvoicesResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.Invoice]?
    }
    
    public struct DeleteInvoiceResponse: Codable {
        public let object: String
        public let deleted: Bool
    }
}
