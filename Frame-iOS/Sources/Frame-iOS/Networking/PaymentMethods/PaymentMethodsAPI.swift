//
//  PaymentMethodsAPI.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
//

import Foundation

// Protocol for Mock Testing
protocol PaymentMethodProtocol {
    //MARK: Methods using async/await
    func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FramePaymentObjects.PaymentMethod]?
    func getPaymentMethodWith(id: String) async throws -> FramePaymentObjects.PaymentMethod?
    func getPaymentMethodsWithCustomer(id: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FramePaymentObjects.PaymentMethod]?
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest) async throws -> FramePaymentObjects.PaymentMethod?
    func updatePaymentMethodWith(id: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest)  async throws -> FramePaymentObjects.PaymentMethod?
    func attachPaymentMethodWith(id: String, request: PaymentMethodRequest.AttachPaymentMethodRequest)  async throws -> FramePaymentObjects.PaymentMethod?
    func detachPaymentMethodWith(id: String) async throws -> FramePaymentObjects.PaymentMethod?
    
    //MARK: Methods using completionHandler
    func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FramePaymentObjects.PaymentMethod]?) -> Void)
    func getPaymentMethodWith(id: String, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void)
    func getPaymentMethodsWithCustomer(id: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FramePaymentObjects.PaymentMethod]?) -> Void)
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void)
    func updatePaymentMethodWith(id: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void)
    func attachPaymentMethodWith(id: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void)
    func detachPaymentMethodWith(id: String, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void)
}

// Payments Methods API
public class PaymentMethodsAPI: PaymentMethodProtocol {
    //MARK: Methods using async/await
    public func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FramePaymentObjects.PaymentMethod]? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getPaymentMethodWith(id: String) async throws -> FramePaymentObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(id: id)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getPaymentMethodsWithCustomer(id: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FramePaymentObjects.PaymentMethod]? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest) async throws -> FramePaymentObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updatePaymentMethodWith(id: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest) async throws -> FramePaymentObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func attachPaymentMethodWith(id: String, request: PaymentMethodRequest.AttachPaymentMethodRequest) async throws -> FramePaymentObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func detachPaymentMethodWith(id: String) async throws -> FramePaymentObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(id: id)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    
    //MARK: Methods using completion handler
    public func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FramePaymentObjects.PaymentMethod]?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func getPaymentMethodWith(id: String, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(id: id)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getPaymentMethodsWithCustomer(id: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FramePaymentObjects.PaymentMethod]?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updatePaymentMethodWith(id: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func attachPaymentMethodWith(id: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(id: id)
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func detachPaymentMethodWith(id: String, completionHandler: @escaping @Sendable (FramePaymentObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(id: id)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FramePaymentObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
