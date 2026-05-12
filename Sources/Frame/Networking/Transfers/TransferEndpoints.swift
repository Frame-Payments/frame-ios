//
//  TransferEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

enum TransferEndpoints: FrameNetworkingEndpoints {
    //MARK: Transfer Endpoints
    case createTransfer
    case getTransferWith(transferId: String)
    case getTransfers(perPage: Int?, page: Int?)

    var endpointURL: String {
        switch self {
        case .createTransfer, .getTransfers:
            return "/v1/transfers"
        case .getTransferWith(let id):
            return "/v1/transfers/\(id)"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .createTransfer:
            return .POST
        default:
            return .GET
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getTransfers(let perPage, let page):
            var queryItems: [URLQueryItem] = []
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            return queryItems
        default:
            return nil
        }
    }
}
