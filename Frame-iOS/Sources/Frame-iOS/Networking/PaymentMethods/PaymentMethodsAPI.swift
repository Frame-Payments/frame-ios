//
//  PaymentMethodsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation

// Protocol for Mock Testing
protocol PaymentMethodProtocol {
    //MARK: Methods using async/await
    func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FrameObjects.PaymentMethod]?
    func getPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod?
    func getPaymentMethodsWithCustomer(customerId: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FrameObjects.PaymentMethod]?
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest) async throws -> FrameObjects.PaymentMethod?
    func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest)  async throws -> FrameObjects.PaymentMethod?
    func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest)  async throws -> FrameObjects.PaymentMethod?
    func detachPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod?
    
    //MARK: Methods using completionHandler
    func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void)
    func getPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func getPaymentMethodsWithCustomer(customerId: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void)
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func detachPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
}

// Payments Methods API
public class PaymentMethodsAPI: PaymentMethodProtocol {
    public init() {}
    
    //MARK: Methods using async/await
    public func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FrameObjects.PaymentMethod]? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getPaymentMethodsWithCustomer(customerId: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?) async throws -> [FrameObjects.PaymentMethod]? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? JSONEncoder().encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func detachPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    
    //MARK: Methods using completion handler
    public func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func getPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getPaymentMethodsWithCustomer(customerId: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? JSONEncoder().encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func detachPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? JSONDecoder().decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
