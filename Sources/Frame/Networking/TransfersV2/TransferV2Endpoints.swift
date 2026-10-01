//
//  TransferV2Endpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

enum TransferV2Endpoints: FrameNetworkingEndpoints {
    case createTransfer(idempotencyKey: String)
    case getTransferWith(transferId: String)
    case getTransfers(perPage: Int?, page: Int?)
    case updateTransfer(transferId: String)
    /// Secret-key confirm sends an `Idempotency-Key`. Publishable + `client_secret` omits it.
    case confirmTransfer(transferId: String, idempotencyKey: String?)
    case captureTransfer(transferId: String, idempotencyKey: String)
    case voidTransfer(transferId: String, idempotencyKey: String)
    case refundTransfer(transferId: String, idempotencyKey: String)

    var endpointURL: String {
        switch self {
        case .createTransfer, .getTransfers:
            return "/v2/transfers"
        case .getTransferWith(let id), .updateTransfer(let id):
            return "/v2/transfers/\(id)"
        case .confirmTransfer(let id, _):
            return "/v2/transfers/\(id)/confirm"
        case .captureTransfer(let id, _):
            return "/v2/transfers/\(id)/capture"
        case .voidTransfer(let id, _):
            return "/v2/transfers/\(id)/void"
        case .refundTransfer(let id, _):
            return "/v2/transfers/\(id)/refund"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .createTransfer, .confirmTransfer, .captureTransfer, .voidTransfer, .refundTransfer:
            return .POST
        case .updateTransfer:
            return .PATCH
        case .getTransferWith, .getTransfers:
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

    var additionalHeaders: [String: String] {
        switch self {
        case .createTransfer(let idempotencyKey),
             .captureTransfer(_, let idempotencyKey),
             .voidTransfer(_, let idempotencyKey),
             .refundTransfer(_, let idempotencyKey):
            return ["Idempotency-Key": idempotencyKey]
        case .confirmTransfer(_, let idempotencyKey):
            guard let idempotencyKey, !idempotencyKey.isEmpty else { return [:] }
            return ["Idempotency-Key": idempotencyKey]
        default:
            return [:]
        }
    }
}
