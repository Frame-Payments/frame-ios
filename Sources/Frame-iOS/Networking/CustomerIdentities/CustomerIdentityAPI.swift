//
//  File.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 8/12/25.
//

import Foundation

// Protocol for Mock Testing
protocol CustomerIdentityProtocol {
    //async/await
    static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest) async throws -> FrameObjects.CustomerIdentity?
    static func getCustomerIdentityWith(customerId: String) async throws -> FrameObjects.CustomerIdentity?
    
    // completionHandlers
    static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?) -> Void)
    static func getCustomerIdentityWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?) -> Void)
}

// Customer Identity API
public class CustomerIdentityAPI: CustomerIdentityProtocol, @unchecked Sendable {
    
    //MARK: Methods using async/await
    public static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest) async throws -> FrameObjects.CustomerIdentity? {
        let endpoint = CustomerIdentityEndpoints.createCustomerIdentity
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func getCustomerIdentityWith(customerId: String) async throws -> FrameObjects.CustomerIdentity? {
       guard !customerId.isEmpty else { return nil }
        let endpoint = CustomerIdentityEndpoints.getCustomerIdentityWith(customerId: customerId)
        
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
    
    //MARK: Methods using completion handler
    public static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?) -> Void) {
        let endpoint = CustomerIdentityEndpoints.createCustomerIdentity
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    public static func getCustomerIdentityWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?) -> Void) {
        let endpoint = CustomerIdentityEndpoints.getCustomerIdentityWith(customerId: customerId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                completionHandler(nil)
            }
        }
    }
}
