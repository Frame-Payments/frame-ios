//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

// Protocol for Mock Testing
protocol CustomerIdentityProtocol {
    //async/await
    static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?)
    static func getCustomerIdentityWith(customerIdentityId: String) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?)
    
    // completionHandlers
    static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void)
    static func getCustomerIdentityWith(customerIdentityId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void)
}

// Customer Identity API
public class CustomerIdentityAPI: CustomerIdentityProtocol, @unchecked Sendable {
    
    //MARK: Methods using async/await
    public static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?) {
        let endpoint = CustomerIdentityEndpoints.createCustomerIdentity
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getCustomerIdentityWith(customerIdentityId: String) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?) {
       guard !customerIdentityId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerIdentityEndpoints.getCustomerIdentityWith(customerIdentityId: customerIdentityId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //MARK: Methods using completion handler
    public static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void) {
        let endpoint = CustomerIdentityEndpoints.createCustomerIdentity
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getCustomerIdentityWith(customerIdentityId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void) {
        guard !customerIdentityId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CustomerIdentityEndpoints.getCustomerIdentityWith(customerIdentityId: customerIdentityId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
