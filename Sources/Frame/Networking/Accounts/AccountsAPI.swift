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
    static func searchAccounts(email: String) async throws -> (AccountResponses.ListAccountsResponse?, NetworkingError?)
    static func getPaymentMethodsForAccount(accountId: String) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?)
    static func restrictAccount(accountId: String) async throws -> (FrameObjects.Account?, NetworkingError?)
    static func unrestrictAccount(accountId: String) async throws -> (FrameObjects.Account?, NetworkingError?)
    static func getPlaidLinkToken(accountId: String) async throws -> (AccountResponses.PlaidLinkTokenResponse?, NetworkingError?)

    // completionHandlers
    static func createAccount(request: AccountRequest.CreateAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func updateAccountWith(accountId: String, request: AccountRequest.UpdateAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func getAccounts(status: FrameObjects.AccountStatus?, type: FrameObjects.AccountType?, externalId: String?, includeDisabled: Bool, completionHandler: @escaping @Sendable (AccountResponses.ListAccountsResponse?, NetworkingError?) -> Void)
    static func getAccountWith(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func deleteAccountWith(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func searchAccounts(email: String, completionHandler: @escaping @Sendable (AccountResponses.ListAccountsResponse?, NetworkingError?) -> Void)
    static func getPaymentMethodsForAccount(accountId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void)
    static func restrictAccount(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func unrestrictAccount(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void)
    static func getPlaidLinkToken(accountId: String, completionHandler: @escaping @Sendable (AccountResponses.PlaidLinkTokenResponse?, NetworkingError?) -> Void)
}

/// Manages account resources in the Frame SDK, providing methods to create, retrieve, update, delete, search, and manage accounts and their associated payment methods.
public class AccountsAPI: AccountsProtocol, @unchecked Sendable {

    //MARK: Methods using async/await

    /// Creates a new account using the provided request body.
    ///
    /// - Note: Standalone account creation is a server operation and authenticates with the secret
    ///   key. During the SDK onboarding flow these calls instead carry the active onboarding-session
    ///   token (`onb_sess_…`) automatically — see ``FrameNetworking/beginOnboardingSession(clientSecret:)``.
    /// - Parameters:
    ///   - request: The details required to create the account.
    ///   - forTesting: When `true`, skips Sift login-event collection; defaults to `false`.
    /// - Returns: A tuple containing the created ``FrameObjects/Account`` and any ``NetworkingError``.
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

    /// Updates an existing account identified by its ID.
    ///
    /// - Note: Standalone account updates are a server operation and authenticate with the secret
    ///   key. During the SDK onboarding flow these calls instead carry the active onboarding-session
    ///   token automatically — see ``FrameNetworking/beginOnboardingSession(clientSecret:)``.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to update.
    ///   - request: The fields to update on the account.
    /// - Returns: A tuple containing the updated ``FrameObjects/Account`` and any ``NetworkingError``.
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

    /// Retrieves a filtered list of accounts.
    /// - Parameters:
    ///   - status: Optional status filter for accounts.
    ///   - type: Optional type filter for accounts.
    ///   - externalId: Optional external identifier to filter by.
    ///   - includeDisabled: When `true`, includes disabled accounts in the results; defaults to `false`.
    /// - Returns: A tuple containing an ``AccountResponses/ListAccountsResponse`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: enumerate accounts from your backend with sk_, not from the app.")
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

    /// Retrieves a single account by its ID.
    ///
    /// - Note: This is a client-safe read and authenticates with the publishable key (`pk_`).
    ///   During the SDK onboarding flow these calls instead carry the active onboarding-session
    ///   token automatically — see ``FrameNetworking/beginOnboardingSession(clientSecret:)``.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to retrieve.
    ///   - forTesting: When `true`, skips Sift login-event collection; defaults to `false`.
    /// - Returns: A tuple containing the matching ``FrameObjects/Account`` and any ``NetworkingError``.
    public static func getAccountWith(accountId: String, forTesting: Bool = false) async throws -> (FrameObjects.Account?, NetworkingError?) {
       guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.getAccountWith(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
            if !forTesting {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.profile?.individual?.email ?? decodedResponse.profile?.business?.email ?? "")
            }
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Deletes the account identified by the given ID.
    /// - Parameter accountId: The unique identifier of the account to delete.
    /// - Returns: A tuple containing the deleted ``FrameObjects/Account`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: delete accounts from your backend with sk_, not from the app.")
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

    /// Searches for accounts matching the given email address.
    /// - Parameter email: The email address to search by.
    /// - Returns: A tuple containing an ``AccountResponses/ListAccountsResponse`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: search accounts from your backend with sk_, not from the app.")
    public static func searchAccounts(email: String) async throws -> (AccountResponses.ListAccountsResponse?, NetworkingError?) {
        guard !email.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.searchAccounts(email: email)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(AccountResponses.ListAccountsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves all payment methods associated with the specified account.
    ///
    /// - Note: This is a client-safe read and authenticates with the publishable key (`pk_`).
    /// - Parameter accountId: The unique identifier of the account whose payment methods to retrieve.
    /// - Returns: A tuple containing a ``PaymentMethodResponses/ListPaymentMethodsResponse`` and any ``NetworkingError``.
    public static func getPaymentMethodsForAccount(accountId: String) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) {
        guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.getAccountPaymentMethods(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Restricts the account identified by the given ID, preventing further activity.
    /// - Parameter accountId: The unique identifier of the account to restrict.
    /// - Returns: A tuple containing the updated ``FrameObjects/Account`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: restrict accounts from your backend with sk_, not from the app.")
    public static func restrictAccount(accountId: String) async throws -> (FrameObjects.Account?, NetworkingError?) {
        guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.restrictAccount(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Removes the restriction on the account identified by the given ID, restoring normal activity.
    /// - Parameter accountId: The unique identifier of the account to unrestrict.
    /// - Returns: A tuple containing the updated ``FrameObjects/Account`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: unrestrict accounts from your backend with sk_, not from the app.")
    public static func unrestrictAccount(accountId: String) async throws -> (FrameObjects.Account?, NetworkingError?) {
        guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.unrestrictAccount(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a Plaid Link token for the specified account, used to initiate bank-account linking.
    /// - Parameter accountId: The unique identifier of the account for which to obtain a Plaid Link token.
    /// - Returns: A tuple containing an ``AccountResponses/PlaidLinkTokenResponse`` and any ``NetworkingError``.
    public static func getPlaidLinkToken(accountId: String) async throws -> (AccountResponses.PlaidLinkTokenResponse?, NetworkingError?) {
        guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = AccountEndpoints.getPlaidLinkToken(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(AccountResponses.PlaidLinkTokenResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //MARK: Methods using completion handler

    /// Completion-handler variant of `createAccount(request:forTesting:)`.
    /// - Parameters:
    ///   - request: The details required to create the account.
    ///   - completionHandler: Called with the created ``FrameObjects/Account`` and any ``NetworkingError``.
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

    /// Completion-handler variant of `updateAccountWith(accountId:request:)`.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to update.
    ///   - request: The fields to update on the account.
    ///   - completionHandler: Called with the updated ``FrameObjects/Account`` and any ``NetworkingError``.
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

    /// Completion-handler variant of `getAccounts(status:type:externalId:includeDisabled:)`.
    /// - Parameters:
    ///   - status: Optional status filter for accounts.
    ///   - type: Optional type filter for accounts.
    ///   - externalId: Optional external identifier to filter by.
    ///   - includeDisabled: When `true`, includes disabled accounts in the results; defaults to `false`.
    ///   - completionHandler: Called with an ``AccountResponses/ListAccountsResponse`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: enumerate accounts from your backend with sk_, not from the app.")
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

    /// Completion-handler variant of `getAccountWith(accountId:forTesting:)`.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to retrieve.
    ///   - completionHandler: Called with the matching ``FrameObjects/Account`` and any ``NetworkingError``.
    public static func getAccountWith(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void) {
        let endpoint = AccountEndpoints.getAccountWith(accountId: accountId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.profile?.individual?.email ?? decodedResponse.profile?.business?.email ?? "")
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `deleteAccountWith(accountId:)`.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to delete.
    ///   - completionHandler: Called with the deleted ``FrameObjects/Account`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: delete accounts from your backend with sk_, not from the app.")
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

    /// Completion-handler variant of `searchAccounts(email:)`.
    /// - Parameters:
    ///   - email: The email address to search by.
    ///   - completionHandler: Called with an ``AccountResponses/ListAccountsResponse`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: search accounts from your backend with sk_, not from the app.")
    public static func searchAccounts(email: String, completionHandler: @escaping @Sendable (AccountResponses.ListAccountsResponse?, NetworkingError?) -> Void) {
        guard !email.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = AccountEndpoints.searchAccounts(email: email)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(AccountResponses.ListAccountsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `getPaymentMethodsForAccount(accountId:)`.
    ///
    /// - Note: This is a client-safe read and authenticates with the publishable key (`pk_`).
    /// - Parameters:
    ///   - accountId: The unique identifier of the account whose payment methods to retrieve.
    ///   - completionHandler: Called with a ``PaymentMethodResponses/ListPaymentMethodsResponse`` and any ``NetworkingError``.
    public static func getPaymentMethodsForAccount(accountId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = AccountEndpoints.getAccountPaymentMethods(accountId: accountId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `restrictAccount(accountId:)`.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to restrict.
    ///   - completionHandler: Called with the updated ``FrameObjects/Account`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: restrict accounts from your backend with sk_, not from the app.")
    public static func restrictAccount(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = AccountEndpoints.restrictAccount(accountId: accountId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `unrestrictAccount(accountId:)`.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to unrestrict.
    ///   - completionHandler: Called with the updated ``FrameObjects/Account`` and any ``NetworkingError``.
    @available(*, deprecated, message: "Server-only: unrestrict accounts from your backend with sk_, not from the app.")
    public static func unrestrictAccount(accountId: String, completionHandler: @escaping @Sendable (FrameObjects.Account?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = AccountEndpoints.unrestrictAccount(accountId: accountId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `getPlaidLinkToken(accountId:)`.
    /// - Parameters:
    ///   - accountId: The unique identifier of the account for which to obtain a Plaid Link token.
    ///   - completionHandler: Called with an ``AccountResponses/PlaidLinkTokenResponse`` and any ``NetworkingError``.
    public static func getPlaidLinkToken(accountId: String, completionHandler: @escaping @Sendable (AccountResponses.PlaidLinkTokenResponse?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = AccountEndpoints.getPlaidLinkToken(accountId: accountId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(AccountResponses.PlaidLinkTokenResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
