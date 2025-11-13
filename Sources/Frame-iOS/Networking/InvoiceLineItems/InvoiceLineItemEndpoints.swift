//
//  InvoiceLineItemEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

import Foundation

enum InvoiceLineItemEndpoints: FrameNetworkingEndpoints {
    //MARK: Invoice Line Items Endpoints
    case getLineItems(invoiceId: String)
    case createLineItem(invoiceId: String)
    case updateLineItem(invoiceId: String, itemId: String)
    case getLineItem(invoiceId: String, itemId: String)
    case deleteLineItem(invoiceId: String, itemId: String)
    
    var endpointURL: String {
        switch self {
        case .createLineItem(let invoiceId), .getLineItems(let invoiceId):
            return "/v1/invoices/\(invoiceId)/line_items"
        case .updateLineItem(let invoiceId, let itemId), .getLineItem(let invoiceId, let itemId), .deleteLineItem(let invoiceId, let itemId):
            return "/v1/invoices/\(invoiceId)/line_items/\(itemId)"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createLineItem:
            return "POST"
        case .updateLineItem:
            return "PATCH"
        case .deleteLineItem:
            return "DELETE"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}
