//
//  CapabilitiesAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

// Protocol for Mock Testing
protocol CapabilitiesProtocol {
    // async/await
    static func getCapabilities(accountId: String) async throws -> (CapabilityResponses.ListCapabilitiesResponse?, NetworkingError?)
    static func requestCapabilities(accountId: String, request: CapabilityRequest.RequestCapabilitiesRequest) async throws -> ([FrameObjects.Capability]?, NetworkingError?)
    static func getCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?)
    static func disableCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?)
    
    // completionHandlers
    static func getCapabilities(accountId: String, completionHandler: @escaping @Sendable (CapabilityResponses.ListCapabilitiesResponse?, NetworkingError?) -> Void)
    static func requestCapabilities(accountId: String, request: CapabilityRequest.RequestCapabilitiesRequest, completionHandler: @escaping @Sendable ([FrameObjects.Capability]?, NetworkingError?) -> Void)
    static func getCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void)
    static func disableCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void)
}

// Capabilities API
public class CapabilitiesAPI: CapabilitiesProtocol, @unchecked Sendable {
    
    //MARK: Methods using async/await
    public static func getCapabilities(accountId: String) async throws -> (CapabilityResponses.ListCapabilitiesResponse?, NetworkingError?) {
        guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = CapabilityEndpoints.getCapabilities(accountId: accountId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CapabilityResponses.ListCapabilitiesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func requestCapabilities(accountId: String, request: CapabilityRequest.RequestCapabilitiesRequest) async throws -> ([FrameObjects.Capability]?, NetworkingError?) {
        guard !accountId.isEmpty else { return (nil, nil) }
        let endpoint = CapabilityEndpoints.requestCapabilities(accountId: accountId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode([FrameObjects.Capability].self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?) {
        guard !accountId.isEmpty, !name.isEmpty else { return (nil, nil) }
        let endpoint = CapabilityEndpoints.getCapabilityWith(accountId: accountId, name: name)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func disableCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?) {
        guard !accountId.isEmpty, !name.isEmpty else { return (nil, nil) }
        let endpoint = CapabilityEndpoints.disableCapabilityWith(accountId: accountId, name: name)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //MARK: Methods using completion handler
    public static func getCapabilities(accountId: String, completionHandler: @escaping @Sendable (CapabilityResponses.ListCapabilitiesResponse?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CapabilityEndpoints.getCapabilities(accountId: accountId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(CapabilityResponses.ListCapabilitiesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func requestCapabilities(accountId: String, request: CapabilityRequest.RequestCapabilitiesRequest, completionHandler: @escaping @Sendable ([FrameObjects.Capability]?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CapabilityEndpoints.requestCapabilities(accountId: accountId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode([FrameObjects.Capability].self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty, !name.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CapabilityEndpoints.getCapabilityWith(accountId: accountId, name: name)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func disableCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty, !name.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CapabilityEndpoints.disableCapabilityWith(accountId: accountId, name: name)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
