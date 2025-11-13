//
//  InvoiceEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/24.
//

import Foundation

enum InvoiceEndpoints: FrameNetworkingEndpoints {
    //MARK: Invoice Endpoints
    case createInvoice
    case updateInvoice(invoiceId: String)
    case getInvoices(perPage: Int?, page: Int?, customer: String?, status: FrameObjects.InvoiceStatus?)
    case getInvoice(invoiceId: String)
    case deleteInvoice(invoiceId: String)
    case issueInvoice(invoiceId: String)
    
    var endpointURL: String {
        switch self {
        case .createInvoice, .getInvoices:
            return "/v1/invoices"
        case .updateInvoice(let invoiceId), .getInvoice(let invoiceId), .deleteInvoice(let invoiceId):
            return "/v1/invoices/\(invoiceId)"
        case .issueInvoice(let invoiceId):
            return "/v1/invoices/\(invoiceId)/issue"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createInvoice, .issueInvoice:
            return "POST"
        case .updateInvoice:
            return "PATCH"
        case .deleteInvoice:
            return "DELETE"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getInvoices(let perPage, let page, let customer, let status):
            var queryItems: [URLQueryItem] = []
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            if let customer { queryItems.append(URLQueryItem(name: "customer", value: "\(customer)")) }
            if let status { queryItems.append(URLQueryItem(name: "status", value: "\(status)")) }
            return queryItems
        default:
            return nil
        }
    }
}

