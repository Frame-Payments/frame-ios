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
    static func createCustomer(request: CustomerRequest.CreateCustomerRequest) async throws -> FrameObjects.Customer?
    static func deleteCustomer(customerId: String) async throws -> CustomerResponses.DeleteCustomerResponse?
    static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest) async throws -> FrameObjects.Customer?
    static func getCustomers(page: Int?, perPage: Int?) async throws -> [FrameObjects.Customer]?
    static func getCustomerWith(customerId: String) async throws -> FrameObjects.Customer?
    static func searchCustomers(request: CustomerRequest.SearchCustomersRequest) async throws -> [FrameObjects.Customer]?
    
    // completionHandlers
    static func createCustomer(request: CustomerRequest.CreateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void)
    static func deleteCustomer(customerId: String, completionHandler: @escaping @Sendable (CustomerResponses.DeleteCustomerResponse?) -> Void)
    static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void)
    static func getCustomers(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void)
    static func getCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void)
    static func searchCustomers(request: CustomerRequest.SearchCustomersRequest, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void)
}

// Customers API
public class CustomersAPI: CustomersProtocol, @unchecked Sendable {
    
    //MARK: Methods using async/await
    public static func createCustomer(request: CustomerRequest.CreateCustomerRequest) async throws -> FrameObjects.Customer? {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func deleteCustomer(customerId: String) async throws -> CustomerResponses.DeleteCustomerResponse? {
       guard !customerId.isEmpty else { return nil }
        let endpoint = CustomerEndpoints.deleteCustomer(customerId: customerId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.DeleteCustomerResponse.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest) async throws -> FrameObjects.Customer? {
        guard !customerId.isEmpty else { return nil }
        let endpoint = CustomerEndpoints.updateCustomer(customerId: customerId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        do {
            let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
            if let data {
                let decodedResponse = try FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data)
                return decodedResponse
            } else {
                return nil
            }
        } catch let error {
            throw error
        }
    }
    
    public static func getCustomers(page: Int? = nil, perPage: Int? = nil) async throws -> [FrameObjects.Customer]? {
        let endpoint = CustomerEndpoints.getCustomers(perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public static func getCustomerWith(customerId: String) async throws -> FrameObjects.Customer? {
       guard !customerId.isEmpty else { return nil }
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func searchCustomers(request: CustomerRequest.SearchCustomersRequest) async throws -> [FrameObjects.Customer]? {
        let endpoint = CustomerEndpoints.searchCustomers
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    //MARK: Methods using completion handler
    public static func createCustomer(request: CustomerRequest.CreateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void) {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func deleteCustomer(customerId: String, completionHandler: @escaping @Sendable (CustomerResponses.DeleteCustomerResponse?) -> Void) {
        let endpoint = CustomerEndpoints.deleteCustomer(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.DeleteCustomerResponse.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void) {
        let endpoint = CustomerEndpoints.updateCustomer(customerId: customerId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func getCustomers(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void) {
        let endpoint = CustomerEndpoints.getCustomers(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public static func getCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void) {
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public static func searchCustomers(request: CustomerRequest.SearchCustomersRequest, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void) {
        let endpoint = CustomerEndpoints.searchCustomers
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
}
