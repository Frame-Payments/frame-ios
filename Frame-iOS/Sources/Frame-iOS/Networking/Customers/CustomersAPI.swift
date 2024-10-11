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
    func createCustomer(request: CustomerRequest.CreateCustomerRequest) async throws -> FrameObjects.Customer?
    func deleteCustomer(customerId: String) async throws -> CustomerResponses.DeleteCustomerResponse?
    func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest) async throws -> FrameObjects.Customer?
    func getCustomers() async throws -> [FrameObjects.Customer]?
    func getCustomerWith(customerId: String) async throws -> FrameObjects.Customer?
    func searchCustomers(request: CustomerRequest.SearchCustomersRequest) async throws -> [FrameObjects.Customer]?
    
    // completionHandlers
    func createCustomer(request: CustomerRequest.CreateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void)
    func deleteCustomer(customerId: String, completionHandler: @escaping @Sendable (CustomerResponses.DeleteCustomerResponse?) -> Void)
    func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void)
    func getCustomers(completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void)
    func getCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void)
    func searchCustomers(request: CustomerRequest.SearchCustomersRequest, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void)
}

// Payments Methods API
public class CustomersAPI: CustomersProtocol, @unchecked Sendable {
    public init() {}
    
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    
    //MARK: Methods using async/await
    public func createCustomer(request: CustomerRequest.CreateCustomerRequest) async throws -> FrameObjects.Customer? {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func deleteCustomer(customerId: String) async throws -> CustomerResponses.DeleteCustomerResponse? {
        let endpoint = CustomerEndpoints.deleteCustomer(customerId: customerId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(CustomerResponses.DeleteCustomerResponse.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest) async throws -> FrameObjects.Customer? {
        let endpoint = CustomerEndpoints.updateCustomer(customerId: customerId)
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getCustomers() async throws -> [FrameObjects.Customer]? {
        let endpoint = CustomerEndpoints.getCustomers
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getCustomerWith(customerId: String) async throws -> FrameObjects.Customer? {
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func searchCustomers(request: CustomerRequest.SearchCustomersRequest) async throws -> [FrameObjects.Customer]? {
        let endpoint = CustomerEndpoints.getCustomers
        let requestBody = try? jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    //MARK: Methods using completion handler
    public func createCustomer(request: CustomerRequest.CreateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void) {
        let endpoint = CustomerEndpoints.createCustomer
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func deleteCustomer(customerId: String, completionHandler: @escaping @Sendable (CustomerResponses.DeleteCustomerResponse?) -> Void) {
        let endpoint = CustomerEndpoints.deleteCustomer(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(CustomerResponses.DeleteCustomerResponse.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updateCustomerWith(customerId: String, request: CustomerRequest.UpdateCustomerRequest, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void) {
        let endpoint = CustomerEndpoints.updateCustomer(customerId: customerId)
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getCustomers(completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void) {
        let endpoint = CustomerEndpoints.getCustomers
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func getCustomerWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.Customer?) -> Void) {
        let endpoint = CustomerEndpoints.getCustomerWith(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(FrameObjects.Customer.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func searchCustomers(request: CustomerRequest.SearchCustomersRequest, completionHandler: @escaping @Sendable ([FrameObjects.Customer]?) -> Void) {
        let endpoint = CustomerEndpoints.searchCustomers
        let requestBody = try? jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? self.jsonDecoder.decode(CustomerResponses.ListCustomersResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
}
