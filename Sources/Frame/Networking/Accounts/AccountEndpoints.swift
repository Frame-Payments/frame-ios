//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

enum AccountEndpoints: FrameNetworkingEndpoints {
    //MARK: Account Endpoints
    case createAccount
    case updateAccount(accountId: String)
    case getAccounts(status: FrameObjects.AccountStatus?, type: FrameObjects.AccountType? , externalId: String?, includeDisabled: Bool = false)
    case getAccountWith(accountId: String)
    case deleteAccountWith(accountId: String)
    
    var endpointURL: String {
        switch self {
        case .createAccount, .getAccounts:
            return "/v1/accounts"
        case .updateAccount(let accountId), .getAccountWith(let accountId), .deleteAccountWith(let accountId):
            return "/v1/accounts/\(accountId)"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .createAccount:
            return .POST
        case .updateAccount:
            return .PATCH
        case .deleteAccountWith:
            return .DELETE
        default:
            return .GET
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getAccounts(let status, let type, let externalId, let includeDisabled):
            var queryItems: [URLQueryItem] = []
            if let status { queryItems.append(URLQueryItem(name: "status", value: status.rawValue)) }
            if let type { queryItems.append(URLQueryItem(name: "type", value: type.rawValue)) }
            if let externalId { queryItems.append(URLQueryItem(name: "status", value: externalId)) }
            queryItems.append(URLQueryItem(name: "include_disabled", value: includeDisabled.description))
            return queryItems
        default:
            return nil
        }
    }
}
