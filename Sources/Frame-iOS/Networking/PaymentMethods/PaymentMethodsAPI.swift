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
    static func getPaymentMethods(page: Int?, perPage: Int?) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?)
    static func getPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func getPaymentMethodsWithCustomer(customerId: String) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?)
    static func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, encryptData: Bool) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest)  async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest)  async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func detachPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func blockPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    static func unblockPaymentMethodWith(paymentMethodId: String) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?)
    
    //MARK: Methods using completionHandler
    static func getPaymentMethods(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void)
    static func getPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func getPaymentMethodsWithCustomer(customerId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void)
    static func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, encryptData: Bool, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func updatePaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func attachPaymentMethodWith(paymentMethodId: String, request: PaymentMethodRequest.AttachPaymentMethodRequest, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func detachPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func blockPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
    static func unblockPaymentMethodWith(paymentMethodId: String, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void)
}

// Payments Methods API
public class PaymentMethodsAPI: PaymentMethodProtocol, @unchecked Sendable {
    //MARK: Methods using async/await
    public static func getPaymentMethods(page: Int? = nil, perPage: Int? = nil) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethods(perPage: perPage, page: page)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
   
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
    
    public static func getPaymentMethodsWithCustomer(customerId: String) async throws -> (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) {
      guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, encryptData: Bool = true) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
        // Ensure evervault is configured before continuing
        if !FrameNetworking.shared.isEvervaultConfigured {
            FrameNetworking.shared.configureEvervault()
        }
        
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        
        var encryptedRequest = request
        if encryptData {
            encryptedRequest.cardNumber = try await Evervault.shared.encrypt(request.cardNumber) as! String
            encryptedRequest.cvc = try await Evervault.shared.encrypt(request.cvc) as! String
        }
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(encryptedRequest)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
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
    
    
    //MARK: Methods using completion handler
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
    
    public static func getPaymentMethodsWithCustomer(customerId: String, completionHandler: @escaping @Sendable (PaymentMethodResponses.ListPaymentMethodsResponse?, NetworkingError?) -> Void) {
        let endpoint = PaymentMethodEndpoints.getPaymentMethodsWithCustomer(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(PaymentMethodResponses.ListPaymentMethodsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest, encryptData: Bool = true, completionHandler: @escaping @Sendable (FrameObjects.PaymentMethod?, NetworkingError?) -> Void) {
        let immutableRequest = request // Capture as a local constant

        Task {
            do {
                let endpoint = PaymentMethodEndpoints.createPaymentMethod
                var encryptedRequest = immutableRequest
                if encryptData {
                    encryptedRequest.cardNumber = try await Evervault.shared.encrypt(immutableRequest.cardNumber) as! String
                    encryptedRequest.cvc = try await Evervault.shared.encrypt(immutableRequest.cvc) as! String
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
}
