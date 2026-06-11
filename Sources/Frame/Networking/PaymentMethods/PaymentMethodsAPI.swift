//
//  PaymentMethodsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation
import EvervaultCore

// https://docs.framepayments.com/api/payment_methods

/// Internal protocol that defines the full set of async/await and completion-handler
/// operations available on the Payment Methods resource.
protocol PaymentMethodProtocol {
    //MARK: Methods using async/await
    static func getPaymentMethods(page: Int?, perPage: Int?) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?)
    static func getPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func getPaymentMethodsWithCustomer(customerId: String, forTesting: Bool) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?)
    static func getPaymentMethodsWithAccount(accountId: String, forTesting: Bool) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?)
    static func createCardPaymentMethod(request: PaymentMethodRequest.CreateCardPaymentMethodRequest, encryptData: Bool) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func createACHPaymentMethod(request: PaymentMethodRequest.CreateACHPaymentMethodRequest) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest)  async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest)  async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func detachPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func blockPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func unblockPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func connectPlaidBankAccount(request: PaymentMethodRequest.ConnectPlaidBankAccountRequest) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)

    //MARK: Methods using completionHandler
    static func getPaymentMethods(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void)
    static func getPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func getPaymentMethodsWithCustomer(customerId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void)
    static func getPaymentMethodsWithAccount(accountId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void)
    static func createCardPaymentMethod(request: PaymentMethodRequest.CreateCardPaymentMethodRequest, encryptData: Bool, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func createACHPaymentMethod(request: PaymentMethodRequest.CreateACHPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func detachPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func blockPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func unblockPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func connectPlaidBankAccount(request: PaymentMethodRequest.ConnectPlaidBankAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
}

/// Manages the Payment Methods resource in the Frame Payments API.
///
/// `PaymentMethodsAPI` provides static methods for creating, retrieving, updating,
/// attaching, detaching, blocking, and connecting payment methods (card and ACH).
/// Each operation is available in both async/await and completion-handler forms.
public class PaymentMethodsAPI: PaymentMethodProtocol, @unchecked Sendable {
    //MARK: Methods using async/await

    /// Retrieves a paginated list of all payment methods.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve, or `nil` for the default first page.
    ///   - perPage: The number of results per page, or `nil` to use the API default.
    /// - Returns: A tuple containing the decoded list response and an optional ``NetworkingError``.
    public static func getPaymentMethods(page: Int? = nil, perPage: Int? = nil) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods(perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single payment method by its identifier.
    ///
    /// - Parameter paymentMethodId: The unique identifier of the payment method to fetch.
    /// - Returns: A tuple containing the decoded ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func getPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
      guard !paymentMethodId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.getPaymentMethodWith(paymentMethodId: paymentMethodId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves all payment methods associated with a specific customer.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer.
    ///   - forTesting: Pass `true` to suppress Sift fraud-signal collection during tests.
    /// - Returns: A tuple containing the decoded list response and an optional ``NetworkingError``.
    public static func getPaymentMethodsWithCustomer(customerId: String, forTesting: Bool = false) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) {
      guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            if !forTesting {
                // Redundancy incase no Customer API calls are ever made.
                SiftManager.collectLoginEvent(customerId: customerId, email: "")
            }
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves all payment methods associated with a specific account.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account.
    ///   - forTesting: Pass `true` to suppress Sift fraud-signal collection during tests.
    /// - Returns: A tuple containing the decoded list response and an optional ``NetworkingError``.
    public static func getPaymentMethodsWithAccount(accountId: String, forTesting: Bool = false) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) {
      guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithAccount(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            if !forTesting {
                // Redundancy incase no Customer API calls are ever made.
                SiftManager.collectLoginEvent(customerId: accountId, email: "")
            }
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // Note: You do not need to encrypt if you are using card details the EncryptedPaymentCardInput element
    /// Creates a new card payment method, optionally encrypting sensitive card data via Evervault.
    ///
    /// - Parameters:
    ///   - request: The ``PaymentMethodRequest/CreateCardPaymentMethodRequest`` containing card details.
    ///   - encryptData: When `true` (default), card number and CVC are encrypted before transmission.
    ///     Pass `false` when card data was already encrypted by the `EncryptedPaymentCardInput` element.
    /// - Returns: A tuple containing the created ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func createCardPaymentMethod(request: PaymentMethodRequest.CreateCardPaymentMethodRequest, encryptData: Bool = true) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod

        var encryptedRequest = request
        if encryptData {
            // Ensure evervault is configured before continuing
            if !FrameNetworking.shared.isEvervaultConfigured {
                FrameNetworking.shared.configureEvervault()
            }

            guard let encryptedCardNumber = try await Evervault.shared.encrypt(request.cardNumber) as? String,
                  let encryptedCvc = try await Evervault.shared.encrypt(request.cvc) as? String else {
                throw NetworkingError.unknownError
            }
            encryptedRequest.cardNumber = encryptedCardNumber
            encryptedRequest.cvc = encryptedCvc
        }

        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(encryptedRequest)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Creates a new ACH bank-account payment method.
    ///
    /// - Parameter request: The ``PaymentMethodRequest/CreateACHPaymentMethodRequest`` containing bank account details.
    /// - Returns: A tuple containing the created ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func createACHPaymentMethod(request: PaymentMethodRequest.CreateACHPaymentMethodRequest) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Updates mutable fields on an existing payment method.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to update.
    ///   - request: The ``PaymentMethodRequest/UpdatePaymentMethodRequest`` containing the fields to change.
    /// - Returns: A tuple containing the updated ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
        guard !paymentMethodId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Attaches a payment method to a customer or account.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to attach.
    ///   - request: The ``PaymentMethodRequest/AttachPaymentMethodRequest`` specifying the target customer or account.
    /// - Returns: A tuple containing the updated ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
    guard !paymentMethodId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Detaches a payment method from its associated customer or account.
    ///
    /// - Parameter paymentMethodId: The unique identifier of the payment method to detach.
    /// - Returns: A tuple containing the detached ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func detachPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
      guard !paymentMethodId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(paymentMethodId: paymentMethodId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Blocks a payment method, preventing it from being used for future transactions.
    ///
    /// - Parameter paymentMethodId: The unique identifier of the payment method to block.
    /// - Returns: A tuple containing the blocked ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func blockPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
      guard !paymentMethodId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.blockPaymentMethodWith(paymentMethodId: paymentMethodId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Unblocks a previously blocked payment method, re-enabling it for transactions.
    ///
    /// - Parameter paymentMethodId: The unique identifier of the payment method to unblock.
    /// - Returns: A tuple containing the unblocked ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func unblockPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
      guard !paymentMethodId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.unblockPaymentMethodWith(paymentMethodId: paymentMethodId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Creates an ACH payment method by linking a bank account through Plaid.
    ///
    /// - Parameter request: The ``PaymentMethodRequest/ConnectPlaidBankAccountRequest`` containing the Plaid link token and account details.
    /// - Returns: A tuple containing the created ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func connectPlaidBankAccount(request: PaymentMethodRequest.ConnectPlaidBankAccountRequest) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
        let endpoint = PaymentMethodEndpoints.connectPlaidBankAccount
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //MARK: Methods using completion handler

    /// Completion-handler variant of ``getPaymentMethods(page:perPage:)``.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve, or `nil` for the default first page.
    ///   - perPage: The number of results per page, or `nil` to use the API default.
    ///   - completionHandler: Called with the decoded list response and an optional ``NetworkingError``.
    public static func getPaymentMethods(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods(perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getPaymentMethodWith(paymentMethodId:)``.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to fetch.
    ///   - completionHandler: Called with the decoded ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func getPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodWith(paymentMethodId: paymentMethodId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getPaymentMethodsWithCustomer(customerId:forTesting:)``.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer.
    ///   - completionHandler: Called with the decoded list response and an optional ``NetworkingError``.
    public static func getPaymentMethodsWithCustomer(customerId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                SiftManager.collectLoginEvent(customerId: customerId, email: "")
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getPaymentMethodsWithAccount(accountId:forTesting:)``.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account.
    ///   - completionHandler: Called with the decoded list response and an optional ``NetworkingError``.
    public static func getPaymentMethodsWithAccount(accountId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithAccount(accountId: accountId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                SiftManager.collectLoginEvent(customerId: accountId, email: "")
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    // Note: You do not need to encrypt if you are using card details the EncryptedPaymentCardInput element
    /// Completion-handler variant of ``createCardPaymentMethod(request:encryptData:)``.
    ///
    /// - Parameters:
    ///   - request: The ``PaymentMethodRequest/CreateCardPaymentMethodRequest`` containing card details.
    ///   - encryptData: When `true` (default), card number and CVC are encrypted before transmission.
    ///     Pass `false` when card data was already encrypted by the `EncryptedPaymentCardInput` element.
    ///   - completionHandler: Called with the created ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func createCardPaymentMethod(request: PaymentMethodRequest.CreateCardPaymentMethodRequest, encryptData: Bool = true, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let immutableRequest = request

        Task {
            do {
                let endpoint = PaymentMethodEndpoints.createPaymentMethod
                var encryptedRequest = immutableRequest
                if encryptData {
                    // Ensure evervault is configured before continuing
                    if !FrameNetworking.shared.isEvervaultConfigured {
                        FrameNetworking.shared.configureEvervault()
                    }

                    guard let encryptedCardNumber = try await Evervault.shared.encrypt(immutableRequest.cardNumber) as? String,
                          let encryptedCvc = try await Evervault.shared.encrypt(immutableRequest.cvc) as? String else {
                        completionHandler(nil, nil)
                        return
                    }
                    encryptedRequest.cardNumber = encryptedCardNumber
                    encryptedRequest.cvc = encryptedCvc
                }

                let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(encryptedRequest)

                let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
                if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                    completionHandler(decodedResponse, error)
                } else {
                    completionHandler(nil, error)
                }
            } catch {
                completionHandler(nil, nil)
            }
        }
    }

    /// Completion-handler variant of ``createACHPaymentMethod(request:)``.
    ///
    /// - Parameters:
    ///   - request: The ``PaymentMethodRequest/CreateACHPaymentMethodRequest`` containing bank account details.
    ///   - completionHandler: Called with the created ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func createACHPaymentMethod(request: PaymentMethodRequest.CreateACHPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``updatePaymentMethodWith(paymentMethodId:request:)``.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to update.
    ///   - request: The ``PaymentMethodRequest/UpdatePaymentMethodRequest`` containing the fields to change.
    ///   - completionHandler: Called with the updated ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``attachPaymentMethodWith(paymentMethodId:request:)``.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to attach.
    ///   - request: The ``PaymentMethodRequest/AttachPaymentMethodRequest`` specifying the target customer or account.
    ///   - completionHandler: Called with the updated ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``detachPaymentMethodWith(paymentMethodId:)``.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to detach.
    ///   - completionHandler: Called with the detached ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func detachPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(paymentMethodId: paymentMethodId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``blockPaymentMethodWith(paymentMethodId:)``.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to block.
    ///   - completionHandler: Called with the blocked ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func blockPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.blockPaymentMethodWith(paymentMethodId: paymentMethodId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``unblockPaymentMethodWith(paymentMethodId:)``.
    ///
    /// - Parameters:
    ///   - paymentMethodId: The unique identifier of the payment method to unblock.
    ///   - completionHandler: Called with the unblocked ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func unblockPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.unblockPaymentMethodWith(paymentMethodId: paymentMethodId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``connectPlaidBankAccount(request:)``.
    ///
    /// - Parameters:
    ///   - request: The ``PaymentMethodRequest/ConnectPlaidBankAccountRequest`` containing the Plaid link token and account details.
    ///   - completionHandler: Called with the created ``FrameObjects/PaymentMethod`` and an optional ``NetworkingError``.
    public static func connectPlaidBankAccount(request: PaymentMethodRequest.ConnectPlaidBankAccountRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.connectPlaidBankAccount
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
