//
//  CustomersAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

// Protocol for Mock Testing
protocol CustomersProtocol {
    //async/await
    static func createCustomer(request: CustomerRequest.CreateCustomerRequest, forTesting: Bool) async throws -> (FrameObjects.Customer?, NetworkingError?)
    static func deleteCustomer(customerId: String) async throws -> (CustomerResponses.DeleteCustomerResponse?, NetworkingError?)
    static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest) async throws -> (FrameObjects.Customer?, NetworkingError?)
    static func getCustomers(page: Int?, perPage: Int?) async throws -> (CustomerResponses.ListCustomersResponse?, NetworkingError?)
    static func getCustomerWith(customerId: String, forTesting: Bool) async throws -> (FrameObjects.Customer?, NetworkingError?)
    static func searchCustomers(request: CustomerRequest.SearchCustomersRequest) async throws -> ([FrameObjects.Customer]?, NetworkingError?)
    static func blockCustomerWith(customerId: String) async throws -> (FrameObjects.Customer?, NetworkingError?)
    static func unblockCustomerWith(customerId: String) async throws -> (FrameObjects.Customer?, NetworkingError?)

    // completionHandlers
    static func createCustomer(request: CustomerRequest.CreateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void)
    static func deleteCustomer(customerId: String, completionHandler: @escaping @Sendable (CustomerResponses.DeleteCustomerResponse?, NetworkingError?) -> Void)
    static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void)
    static func getCustomers(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable (CustomerResponses.ListCustomersResponse?, NetworkingError?) -> Void)
    static func getCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void)
    static func searchCustomers(request: CustomerRequest.SearchCustomersRequest, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?, NetworkingError?) -> Void)
    static func blockCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void)
    static func unblockCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void)
}

/// Manages the Customers resource, providing methods to create, retrieve, update, delete, search, block, and unblock customer records via the Frame API.
public class CustomersAPI: CustomersProtocol, @unchecked Sendable {

    //MARK: Methods using async/await

    /// Creates a new customer record using the provided request body.
    ///
    /// - Parameters:
    ///   - request: The customer creation parameters.
    ///   - forTesting: Pass `true` to skip Sift login-event collection; defaults to `false`.
    /// - Returns: A tuple containing the created ``FrameObjects/Customer`` on success, or a ``NetworkingError`` on failure.
    public static func createCustomer(request: CustomerRequest.CreateCustomerRequest, forTesting: Bool = false) async throws -> (FrameObjects.Customer?, NetworkingError?) {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            if !forTesting {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.email ?? "")
            }
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Deletes the customer identified by the given ID.
    ///
    /// - Parameter customerId: The unique identifier of the customer to delete.
    /// - Returns: A tuple containing a ``CustomerResponses/DeleteCustomerResponse`` on success, or a ``NetworkingError`` on failure.
    public static func deleteCustomer(customerId: String) async throws -> (CustomerResponses.DeleteCustomerResponse?, NetworkingError?) {
       guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerEndpoints.deleteCustomer(customerId: customerId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.DeleteCustomerResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Updates the customer identified by the given ID with the provided request body.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer to update.
    ///   - request: The fields to update on the customer record.
    /// - Returns: A tuple containing the updated ``FrameObjects/Customer`` on success, or a ``NetworkingError`` on failure.
    public static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest) async throws -> (FrameObjects.Customer?, NetworkingError?) {
        guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerEndpoints.updateCustomer(customerId: customerId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a paginated list of all customers.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve; pass `nil` to use the API default.
    ///   - perPage: The number of results per page; pass `nil` to use the API default.
    /// - Returns: A tuple containing a ``CustomerResponses/ListCustomersResponse`` on success, or a ``NetworkingError`` on failure.
    public static func getCustomers(page: Int? = nil, perPage: Int? = nil) async throws -> (CustomerResponses.ListCustomersResponse?, NetworkingError?) {
        let endpoint = CustomerEndpoints.getCustomers(perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single customer by their unique identifier.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer to retrieve.
    ///   - forTesting: Pass `true` to skip Sift login-event collection; defaults to `false`.
    /// - Returns: A tuple containing the matching ``FrameObjects/Customer`` on success, or a ``NetworkingError`` on failure.
    public static func getCustomerWith(customerId: String, forTesting: Bool = false) async throws -> (FrameObjects.Customer?, NetworkingError?) {
       guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            if !forTesting {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.email ?? "")
            }
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Searches for customers matching the criteria in the provided request body.
    ///
    /// - Parameter request: The search parameters used to filter customers.
    /// - Returns: A tuple containing an array of matching ``FrameObjects/Customer`` objects on success, or a ``NetworkingError`` on failure.
    public static func searchCustomers(request: CustomerRequest.SearchCustomersRequest) async throws -> ([FrameObjects.Customer]?, NetworkingError?) {
        let endpoint = CustomerEndpoints.searchCustomers
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
            return (decodedResponse.data, error)
        } else {
            return (nil, error)
        }
    }

    /// Blocks the customer identified by the given ID, preventing them from transacting.
    ///
    /// - Parameter customerId: The unique identifier of the customer to block.
    /// - Returns: A tuple containing the updated ``FrameObjects/Customer`` on success, or a ``NetworkingError`` on failure.
    public static func blockCustomerWith(customerId: String) async throws -> (FrameObjects.Customer?, NetworkingError?) {
        guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerEndpoints.blockCustomer(customerId: customerId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Unblocks the customer identified by the given ID, restoring their ability to transact.
    ///
    /// - Parameter customerId: The unique identifier of the customer to unblock.
    /// - Returns: A tuple containing the updated ``FrameObjects/Customer`` on success, or a ``NetworkingError`` on failure.
    public static func unblockCustomerWith(customerId: String) async throws -> (FrameObjects.Customer?, NetworkingError?) {
       guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerEndpoints.unblockCustomer(customerId: customerId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //MARK: Methods using completion handler

    /// Completion-handler variant of ``createCustomer(request:forTesting:)``.
    ///
    /// - Parameters:
    ///   - request: The customer creation parameters.
    ///   - completionHandler: Called with the created ``FrameObjects/Customer`` or a ``NetworkingError``.
    public static func createCustomer(request: CustomerRequest.CreateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.email ?? "")
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``deleteCustomer(customerId:)``.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer to delete.
    ///   - completionHandler: Called with a ``CustomerResponses/DeleteCustomerResponse`` or a ``NetworkingError``.
    public static func deleteCustomer(customerId: String, completionHandler: @escaping @Sendable (CustomerResponses.DeleteCustomerResponse?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.deleteCustomer(customerId: customerId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.DeleteCustomerResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``updateCustomerWith(customerId:request:)``.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer to update.
    ///   - request: The fields to update on the customer record.
    ///   - completionHandler: Called with the updated ``FrameObjects/Customer`` or a ``NetworkingError``.
    public static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.updateCustomer(customerId: customerId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getCustomers(page:perPage:)``.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve; pass `nil` to use the API default.
    ///   - perPage: The number of results per page; pass `nil` to use the API default.
    ///   - completionHandler: Called with a ``CustomerResponses/ListCustomersResponse`` or a ``NetworkingError``.
    public static func getCustomers(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable (CustomerResponses.ListCustomersResponse?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.getCustomers(perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getCustomerWith(customerId:forTesting:)``.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer to retrieve.
    ///   - completionHandler: Called with the matching ``FrameObjects/Customer`` or a ``NetworkingError``.
    public static func getCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                SiftManager.collectLoginEvent(customerId: decodedResponse.id, email: decodedResponse.email ?? "")
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``searchCustomers(request:)``.
    ///
    /// - Parameters:
    ///   - request: The search parameters used to filter customers.
    ///   - completionHandler: Called with an array of matching ``FrameObjects/Customer`` objects or a ``NetworkingError``.
    public static func searchCustomers(request: CustomerRequest.SearchCustomersRequest, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.searchCustomers
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
                completionHandler(decodedResponse.data, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``blockCustomerWith(customerId:)``.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer to block.
    ///   - completionHandler: Called with the updated ``FrameObjects/Customer`` or a ``NetworkingError``.
    public static func blockCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.blockCustomer(customerId: customerId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``unblockCustomerWith(customerId:)``.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer to unblock.
    ///   - completionHandler: Called with the updated ``FrameObjects/Customer`` or a ``NetworkingError``.
    public static func unblockCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.unblockCustomer(customerId: customerId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
