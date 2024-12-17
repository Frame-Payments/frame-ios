//
//  PaymentMethodsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation
import EvervaultCore

// Protocol for Mock Testing
protocol PaymentMethodProtocol {
    //MARK: Methods using async/await
    func getPaymentMethods(page: Int?, perPage: Int?) async throws -> [FrameObjects.PaymentMethod]?
    func getPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod?
    func getPaymentMethodsWithCustomer(customerId: String) async throws -> [FrameObjects.PaymentMethod]?
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, encryptData: Bool) async throws -> FrameObjects.PaymentMethod?
    func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest)  async throws -> FrameObjects.PaymentMethod?
    func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest)  async throws -> FrameObjects.PaymentMethod?
    func detachPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod?
    
    //MARK: Methods using completionHandler
    func getPaymentMethods(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void)
    func getPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func getPaymentMethodsWithCustomer(customerId: String, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void)
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
    func detachPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void)
}

// Payments Methods API
public class PaymentMethodsAPI: PaymentMethodProtocol, @unchecked Sendable {
    public init(mockSession: URLSessionProtocol? = nil) {
        FrameNetworking.shared.urlSession = mockSession ?? URLSession.shared
    }
    
    //MARK: Methods using async/await
    public func getPaymentMethods(page: Int? = nil, perPage: Int? = nil) async throws -> [FrameObjects.PaymentMethod]? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods(perPage: perPage, page: page)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func getPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func getPaymentMethodsWithCustomer(customerId: String) async throws -> [FrameObjects.PaymentMethod]? {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return decodedResponse.data
        } else {
            return nil
        }
    }
    
    public func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, encryptData: Bool = false) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        
        var encryptedRequest = request
        if encryptData {
            encryptedRequest.cardNumber = try await Evervault.shared.encrypt(request.cardNumber) as! String
            encryptedRequest.cvc = try await Evervault.shared.encrypt(request.cvc) as! String
            encryptedRequest.expMonth = try await Evervault.shared.encrypt(request.expMonth) as! String
            encryptedRequest.expYear = try await Evervault.shared.encrypt(request.expYear) as! String
        }
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(encryptedRequest)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public func detachPaymentMethodWith(paymentMethodId: String) async throws -> FrameObjects.PaymentMethod? {
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    
    //MARK: Methods using completion handler
    public func getPaymentMethods(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func getPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func getPaymentMethodsWithCustomer(customerId: String, completionHandler: @escaping @Sendable ([FrameObjects.PaymentMethod]?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse.data)
            }
        }
    }
    
    public func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.updatePaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.attachPaymentMethodWith(paymentMethodId: paymentMethodId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
    
    public func detachPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?) -> Void) {
        let endpoint = PaymentMethodEndpoints.detachPaymentMethodWith(paymentMethodId: paymentMethodId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
                completionHandler(decodedResponse)
            }
        }
    }
}
