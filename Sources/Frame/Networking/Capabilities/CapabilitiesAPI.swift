//
//  CapabilitiesAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

/// Internal protocol defining the capabilities API surface, used for mock testing.
protocol CapabilitiesProtocol {
    // async/await

    /// Fetches all capabilities for the specified account.
    static func getCapabilities(accountId: String) async throws -> (CapabilityResponses.ListCapabilitiesResponse?, NetworkingError?)

    /// Requests one or more capabilities be enabled for the specified account.
    static func requestCapabilities(accountId: String, request: CapabilityRequest.RequestCapabilitiesRequest) async throws -> ([FrameObjects.Capability]?, NetworkingError?)

    /// Fetches a single capability by name for the specified account.
    static func getCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?)

    /// Disables a named capability for the specified account.
    static func disableCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?)

    // completionHandlers

    /// Completion-handler variant of `getCapabilities(accountId:)`.
    static func getCapabilities(accountId: String, completionHandler: @escaping @Sendable (CapabilityResponses.ListCapabilitiesResponse?, NetworkingError?) -> Void)

    /// Completion-handler variant of `requestCapabilities(accountId:request:)`.
    static func requestCapabilities(accountId: String, request: CapabilityRequest.RequestCapabilitiesRequest, completionHandler: @escaping @Sendable ([FrameObjects.Capability]?, NetworkingError?) -> Void)

    /// Completion-handler variant of `getCapabilityWith(accountId:name:)`.
    static func getCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void)

    /// Completion-handler variant of `disableCapabilityWith(accountId:name:)`.
    static func disableCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void)
}

/// Manages account capability resources in the Frame SDK, providing methods to list, request, retrieve, and disable capabilities.
public class CapabilitiesAPI: CapabilitiesProtocol, @unchecked Sendable {

    //MARK: Methods using async/await

    /// Returns the list of all capabilities associated with the given account.
    ///
    /// - Parameter accountId: The unique identifier of the account whose capabilities are fetched.
    /// - Returns: A tuple containing the decoded list response and any networking error encountered.
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

    /// Requests the specified capabilities be enabled for the given account.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account for which capabilities are requested.
    ///   - request: The request body specifying which capabilities to enable.
    /// - Returns: A tuple containing the updated array of capabilities and any networking error encountered.
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

    /// Fetches a single capability by name for the given account.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account.
    ///   - name: The name of the capability to retrieve.
    /// - Returns: A tuple containing the matching capability and any networking error encountered.
    @available(*, deprecated, message: "Server-only: manage individual capabilities from your backend with sk_, not from the app.")
    public static func getCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?) {
        guard !accountId.isEmpty, !name.isEmpty else { return (nil, nil) }
        let endpoint = CapabilityEndpoints.getCapabilityWith(accountId: accountId, name: name)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Disables the named capability for the given account.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account.
    ///   - name: The name of the capability to disable.
    /// - Returns: A tuple containing the updated capability and any networking error encountered.
    @available(*, deprecated, message: "Server-only: manage individual capabilities from your backend with sk_, not from the app.")
    public static func disableCapabilityWith(accountId: String, name: String) async throws -> (FrameObjects.Capability?, NetworkingError?) {
        guard !accountId.isEmpty, !name.isEmpty else { return (nil, nil) }
        let endpoint = CapabilityEndpoints.disableCapabilityWith(accountId: accountId, name: name)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //MARK: Methods using completion handler

    /// Completion-handler variant of `getCapabilities(accountId:)`.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account whose capabilities are fetched.
    ///   - completionHandler: Called with the decoded list response and any networking error encountered.
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

    /// Completion-handler variant of `requestCapabilities(accountId:request:)`.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account for which capabilities are requested.
    ///   - request: The request body specifying which capabilities to enable.
    ///   - completionHandler: Called with the updated array of capabilities and any networking error encountered.
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

    /// Completion-handler variant of `getCapabilityWith(accountId:name:)`.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account.
    ///   - name: The name of the capability to retrieve.
    ///   - completionHandler: Called with the matching capability and any networking error encountered.
    @available(*, deprecated, message: "Server-only: manage individual capabilities from your backend with sk_, not from the app.")
    public static func getCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty, !name.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CapabilityEndpoints.getCapabilityWith(accountId: accountId, name: name)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `disableCapabilityWith(accountId:name:)`.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account.
    ///   - name: The name of the capability to disable.
    ///   - completionHandler: Called with the updated capability and any networking error encountered.
    @available(*, deprecated, message: "Server-only: manage individual capabilities from your backend with sk_, not from the app.")
    public static func disableCapabilityWith(accountId: String, name: String, completionHandler: @escaping @Sendable (FrameObjects.Capability?, NetworkingError?) -> Void) {
        guard !accountId.isEmpty, !name.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CapabilityEndpoints.disableCapabilityWith(accountId: accountId, name: name)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Capability.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
