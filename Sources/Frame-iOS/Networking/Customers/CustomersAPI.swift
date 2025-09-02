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
    static func createCustomer(request: CustomerRequest.CreateCustomerRequest) async throws -> (FrameObjects.Customer?, NetworkingError?)
    static func deleteCustomer(customerId: String) async throws -> (CustomerResponses.DeleteCustomerResponse?, NetworkingError?)
    static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest) async throws -> (FrameObjects.Customer?, NetworkingError?)
    static func getCustomers(page: Int?, perPage: Int?) async throws -> (CustomerResponses.ListCustomersResponse?, NetworkingError?)
    static func getCustomerWith(customerId: String) async throws -> (FrameObjects.Customer?, NetworkingError?)
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

// Customers API
public class CustomersAPI: CustomersProtocol, @unchecked Sendable {
    
    //MARK: Methods using async/await
    public static func createCustomer(request: CustomerRequest.CreateCustomerRequest) async throws -> (FrameObjects.Customer?, NetworkingError?) {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
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
    
    public static func getCustomers(page: Int? = nil, perPage: Int? = nil) async throws -> (CustomerResponses.ListCustomersResponse?, NetworkingError?) {
        let endpoint = CustomerEndpoints.getCustomers(perPage: perPage, page: page)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getCustomerWith(customerId: String) async throws -> (FrameObjects.Customer?, NetworkingError?) {
       guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
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
    public static func createCustomer(request: CustomerRequest.CreateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
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
    
    public static func getCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?, NetworkingError?) -> Void) {
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
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
