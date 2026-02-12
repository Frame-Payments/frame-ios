//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

// Protocol for Mock Testing
protocol AccountsProtocol {
    //async/await
    static func createAccount(request: AccountRequest.CreateAccountRequest, forTesting: Bool) async throws -> (FrameObjects.Account?, NetworkingError?)
    static func updateAccountWith(accountId: String, request: AccountRequest.UpdateAccountRequest) async throws -> (FrameObjects.Account?, NetworkingError?)
    static func getAccounts(status: FrameObjects.AccountStatus?, type: FrameObjects.AccountType?, externalId: String?, includeDisabled: Bool) async throws -> (AccountResponses.ListAccountsResponse?, NetworkingError?)
    static func getAccountWith(accountId: String, forTesting: Bool) async throws -> (FrameObjects.Account?, NetworkingError?)
    static func deleteAccountWith(accountId: String) async throws -> (FrameObjects.Account?, NetworkingError?)
    
    // completionHandlers
    static func createAccount(request: AccountRequest.CreateAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func updateAccountWith(accountId: String, request: AccountRequest.UpdateAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func getAccounts(status: FrameObjects.AccountStatus?, type: FrameObjects.AccountType?, externalId: String?, includeDisabled: Bool, completionHandler: @escaping @Sendable (AccountResponses.ListAccountsResponse?, NetworkingError?) -> Void)
    static func getAccountWith(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func deleteAccountWith(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
}

// Accounts API
public class AccountsAPI: AccountsProtocol, @unchecked Sendable {
    
    //MARK: Methods using async/await
    public static func createAccount(request: AccountRequest.CreateAccountRequest, forTesting: Bool = false) async throws -> (FrameObjects.Account?, NetworkingError?) {
        let endpoint = AccountEndpoints.createAccount
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
            if !forTesting {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.profile?.individual?.email ?? decodedResponse.profile?.business?.email ?? "")
            }
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func updateAccountWith(accountId: String, request: AccountRequest.UpdateAccountRequest) async throws -> (FrameObjects.Account?, NetworkingError?) {
        guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.updateAccount(accountId: accountId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getAccounts(status: FrameObjects.AccountStatus?, type: FrameObjects.AccountType?, externalId: String?, includeDisabled: Bool = false) async throws -> (AccountResponses.ListAccountsResponse?, NetworkingError?) {
        let endpoint = AccountEndpoints.getAccounts(status: status,
                                                    type: type,
                                                    externalId: externalId,
                                                    includeDisabled: includeDisabled)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(AccountResponses.ListAccountsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getAccountWith(accountId: String, forTesting: Bool = false) async throws -> (FrameObjects.Account?, NetworkingError?) {
       guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.getAccountWith(accountId: accountId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
            if !forTesting {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.profile?.individual?.email ?? decodedResponse.profile?.business?.email ?? "")
            }
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func deleteAccountWith(accountId: String) async throws -> (FrameObjects.Account?, NetworkingError?) {
       guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.deleteAccountWith(accountId: accountId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //MARK: Methods using completion handler
    public static func createAccount(request: AccountRequest.CreateAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void) {
        let endpoint = AccountEndpoints.createAccount
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.profile?.individual?.email ?? decodedResponse.profile?.business?.email ?? "")
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func updateAccountWith(accountId: String, request: AccountRequest.UpdateAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void) {
        let endpoint = AccountEndpoints.updateAccount(accountId: accountId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getAccounts(status: FrameObjects.AccountStatus?, type: FrameObjects.AccountType?, externalId: String?, includeDisabled: Bool = false, completionHandler: @escaping @Sendable (AccountResponses.ListAccountsResponse?, NetworkingError?) -> Void) {
        let endpoint = AccountEndpoints.getAccounts(status: status,
                                                    type: type,
                                                    externalId: externalId,
                                                    includeDisabled: includeDisabled)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(AccountResponses.ListAccountsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getAccountWith(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void) {
        let endpoint = AccountEndpoints.getAccountWith(accountId: accountId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.profile?.individual?.email ?? decodedResponse.profile?.business?.email ?? "")
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func deleteAccountWith(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void) {
        let endpoint = AccountEndpoints.deleteAccountWith(accountId: accountId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
