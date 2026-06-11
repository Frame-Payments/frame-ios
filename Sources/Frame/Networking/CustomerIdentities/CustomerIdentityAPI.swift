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
    static func createCustomerIdentityWith(customerId: String) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?)
    static func getCustomerIdentityWith(customerIdentityId: String) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?)
    static func submitForVerification(customerIdentityId: String) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?)
    static func uploadIdentityDocuments(customerIdentityId: String, identityImages: [FileUpload]) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?)

    // completionHandlers
    static func createCustomerIdentity(request: CustomerIdentityRequest.CreateCustomerIdentityRequest, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void)
    static func createCustomerIdentityWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void)
    static func getCustomerIdentityWith(customerIdentityId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void)
    static func submitForVerification(customerIdentityId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void)
    static func uploadIdentityDocuments(customerIdentityId: String, identityImages: [FileUpload], completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void)
}

/// Manages customer identity verification resources in the Frame SDK.
///
/// ``CustomerIdentityAPI`` provides static methods for creating customer identity records,
/// retrieving them, uploading identity documents, and submitting identities for verification.
/// Each operation is available as both an async/await method and a completion-handler variant.
public class CustomerIdentityAPI: CustomerIdentityProtocol, @unchecked Sendable {

    //MARK: Methods using async/await

    /// Creates a new customer identity using the provided request body.
    ///
    /// - Parameter request: The request body describing the customer identity to create.
    /// - Returns: A tuple containing the created ``FrameObjects/CustomerIdentity`` on success, or a ``NetworkingError`` on failure.
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

    /// Creates a new customer identity associated with an existing customer ID.
    ///
    /// - Parameter customerId: The unique identifier of the customer for whom the identity record will be created.
    /// - Returns: A tuple containing the created ``FrameObjects/CustomerIdentity`` on success, or a ``NetworkingError`` on failure.
    public static func createCustomerIdentityWith(customerId: String) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?) {
       guard !customerId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerIdentityEndpoints.createCustomerIdentityWith(customerId: customerId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a customer identity by its unique identifier.
    ///
    /// - Parameter customerIdentityId: The unique identifier of the customer identity record to fetch.
    /// - Returns: A tuple containing the matching ``FrameObjects/CustomerIdentity`` on success, or a ``NetworkingError`` on failure.
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

    /// Submits a customer identity for verification review.
    ///
    /// - Parameter customerIdentityId: The unique identifier of the customer identity to submit for verification.
    /// - Returns: A tuple containing the updated ``FrameObjects/CustomerIdentity`` on success, or a ``NetworkingError`` on failure.
    public static func submitForVerification(customerIdentityId: String) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?) {
       guard !customerIdentityId.isEmpty else { return (nil, nil) }
        let endpoint = CustomerIdentityEndpoints.submitForVerification(customerIdentityId: customerIdentityId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Uploads identity document images for a customer identity record.
    ///
    /// - Parameters:
    ///   - customerIdentityId: The unique identifier of the customer identity to attach documents to.
    ///   - identityImages: An array of ``FileUpload`` values representing the document images to upload.
    /// - Returns: A tuple containing the updated ``FrameObjects/CustomerIdentity`` on success, or a ``NetworkingError`` on failure.
    public static func uploadIdentityDocuments(customerIdentityId: String, identityImages: [FileUpload]) async throws -> (FrameObjects.CustomerIdentity?, NetworkingError?) {
        guard !customerIdentityId.isEmpty else { return (nil, nil) }

        let endpoint = CustomerIdentityEndpoints.uploadIdentityDocuments(customerIdentityId: customerIdentityId)
        let (data, error) = try await FrameNetworking.shared.performMultipartDataTask(endpoint: endpoint, filesToUpload: identityImages)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //MARK: Methods using completion handler

    /// Completion-handler variant of `createCustomerIdentity(request:)`.
    ///
    /// - Parameters:
    ///   - request: The request body describing the customer identity to create.
    ///   - completionHandler: Called with the created ``FrameObjects/CustomerIdentity`` or a ``NetworkingError``.
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

    /// Completion-handler variant of `createCustomerIdentityWith(customerId:)`.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the customer for whom the identity record will be created.
    ///   - completionHandler: Called with the created ``FrameObjects/CustomerIdentity`` or a ``NetworkingError``.
    public static func createCustomerIdentityWith(customerId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void) {
        guard !customerId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CustomerIdentityEndpoints.createCustomerIdentityWith(customerId: customerId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `getCustomerIdentityWith(customerIdentityId:)`.
    ///
    /// - Parameters:
    ///   - customerIdentityId: The unique identifier of the customer identity record to fetch.
    ///   - completionHandler: Called with the matching ``FrameObjects/CustomerIdentity`` or a ``NetworkingError``.
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

    /// Completion-handler variant of `submitForVerification(customerIdentityId:)`.
    ///
    /// - Parameters:
    ///   - customerIdentityId: The unique identifier of the customer identity to submit for verification.
    ///   - completionHandler: Called with the updated ``FrameObjects/CustomerIdentity`` or a ``NetworkingError``.
    public static func submitForVerification(customerIdentityId: String, completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void) {
        guard !customerIdentityId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CustomerIdentityEndpoints.submitForVerification(customerIdentityId: customerIdentityId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `uploadIdentityDocuments(customerIdentityId:identityImages:)`.
    ///
    /// - Parameters:
    ///   - customerIdentityId: The unique identifier of the customer identity to attach documents to.
    ///   - identityImages: An array of ``FileUpload`` values representing the document images to upload.
    ///   - completionHandler: Called with the updated ``FrameObjects/CustomerIdentity`` or a ``NetworkingError``.
    public static func uploadIdentityDocuments(customerIdentityId: String, identityImages: [FileUpload], completionHandler: @escaping @Sendable (FrameObjects.CustomerIdentity?, NetworkingError?) -> Void) {
        guard !customerIdentityId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = CustomerIdentityEndpoints.uploadIdentityDocuments(customerIdentityId: customerIdentityId)

        FrameNetworking.shared.performMultipartDataTask(endpoint: endpoint, filesToUpload: identityImages) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.CustomerIdentity.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
