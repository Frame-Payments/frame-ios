//
//  ChargeIntentsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

// Protocol for Mock Testing
protocol ChargeIntentsProtocol {
    //async/await
    static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func confirmChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func cancelChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func voidRemainingChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func getAllChargeIntents(page: Int?, perPage: Int?) async throws -> (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?)
    static func getChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)
    static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?)

    // completionHandlers
    static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func voidRemainingChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func getAllChargeIntents(page: Int?, perPage: Int?, completionHandler: @escaping @Sendable (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?) -> Void)
    static func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
    static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void)
}

/// Manages the Charge Intents resource, providing static methods to create, capture, confirm,
/// cancel, void, retrieve, list, and update charge intents via the Frame API.
public class ChargeIntentsAPI: ChargeIntentsProtocol, @unchecked Sendable {

    // MARK: - async/await

    /// Creates a new charge intent, automatically attaching the current Sonar session ID and client IP fraud signals.
    ///
    /// - Parameter request: The parameters for the charge intent to create.
    /// - Returns: A tuple containing the created ``FrameObjects/ChargeIntent`` on success, or a ``NetworkingError`` on failure.
    public static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        let endpoint = ChargeIntentEndpoints.createChargeIntent

        // Automatically insert client's ip address for charge intent
        var updatedRequest = request
        updatedRequest.sonarSessionId = FrameNetworking.shared.currentSonarSessionId()
        updatedRequest.fraudSignals = ChargeIntentsRequests.FraudSignals(clientIp: SiftManager.getIPAddress())

        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(updatedRequest)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Captures a previously authorised charge intent.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent to capture.
    ///   - request: Additional capture parameters such as amount to capture.
    /// - Returns: A tuple containing the updated ``FrameObjects/ChargeIntent`` on success, or a ``NetworkingError`` on failure.
    public static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Confirms a charge intent, moving it to an authorised state.
    ///
    /// - Parameter intentId: The unique identifier of the charge intent to confirm.
    /// - Returns: A tuple containing the confirmed ``FrameObjects/ChargeIntent`` on success, or a ``NetworkingError`` on failure.
    public static func confirmChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
//            SiftManager.addNewSiftEvent(transactionType: .authorize, eventId: decodedResponse.id)
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Cancels a charge intent that has not yet been captured.
    ///
    /// - Parameter intentId: The unique identifier of the charge intent to cancel.
    /// - Returns: A tuple containing the cancelled ``FrameObjects/ChargeIntent`` on success, or a ``NetworkingError`` on failure.
    public static func cancelChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a paginated list of all charge intents for the authenticated merchant.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve, or `nil` for the first page.
    ///   - perPage: The number of results per page, or `nil` to use the API default.
    /// - Returns: A tuple containing a ``ChargeIntentResponses/ListChargeIntentsResponse`` on success, or a ``NetworkingError`` on failure.
    public static func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil) async throws -> (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?) {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Fetches a single charge intent by its identifier.
    ///
    /// - Parameter intentId: The unique identifier of the charge intent to retrieve.
    /// - Returns: A tuple containing the matching ``FrameObjects/ChargeIntent`` on success, or a ``NetworkingError`` on failure.
    public static func getChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Updates mutable fields on an existing charge intent.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent to update.
    ///   - request: The fields to update on the charge intent.
    /// - Returns: A tuple containing the updated ``FrameObjects/ChargeIntent`` on success, or a ``NetworkingError`` on failure.
    public static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Voids the uncaptured remainder of a partially captured charge intent.
    ///
    /// - Parameter intentId: The unique identifier of the charge intent whose remaining authorisation should be voided.
    /// - Returns: A tuple containing the updated ``FrameObjects/ChargeIntent`` on success, or a ``NetworkingError`` on failure.
    public static func voidRemainingChargeIntent(intentId: String) async throws -> (FrameObjects.ChargeIntent?, NetworkingError?) {
        guard !intentId.isEmpty else { return (nil, nil) }
        let endpoint = ChargeIntentEndpoints.voidRemainingChargeIntent(intentId: intentId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // MARK: - Completion-handler variants

    /// Completion-handler variant of ``createChargeIntentAsync(_:)``.
    ///
    /// - Parameters:
    ///   - request: The parameters for the charge intent to create.
    ///   - completionHandler: Called with the created ``FrameObjects/ChargeIntent`` or a ``NetworkingError``.
    public static func createChargeIntent(request: ChargeIntentsRequests.CreateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.createChargeIntent

        var updatedRequest = request
        updatedRequest.sonarSessionId = FrameNetworking.shared.currentSonarSessionId()
        updatedRequest.fraudSignals = ChargeIntentsRequests.FraudSignals(clientIp: SiftManager.getIPAddress())

        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(updatedRequest)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``captureChargeIntentAsync(_:request:)``.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent to capture.
    ///   - request: Additional capture parameters such as amount to capture.
    ///   - completionHandler: Called with the updated ``FrameObjects/ChargeIntent`` or a ``NetworkingError``.
    public static func captureChargeIntent(intentId: String, request: ChargeIntentsRequests.CaptureChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.captureChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``confirmChargeIntentAsync(_:)``.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent to confirm.
    ///   - completionHandler: Called with the confirmed ``FrameObjects/ChargeIntent`` or a ``NetworkingError``.
    public static func confirmChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.confirmChargeIntent(intentId: intentId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
//                SiftManager.addNewSiftEvent(transactionType: .authorize, eventId: decodedResponse.id)
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``cancelChargeIntentAsync(_:)``.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent to cancel.
    ///   - completionHandler: Called with the cancelled ``FrameObjects/ChargeIntent`` or a ``NetworkingError``.
    public static func cancelChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.cancelChargeIntent(intentId: intentId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getAllChargeIntentsAsync(page:perPage:)``.
    ///
    /// - Parameters:
    ///   - page: The page number to retrieve, or `nil` for the first page.
    ///   - perPage: The number of results per page, or `nil` to use the API default.
    ///   - completionHandler: Called with a ``ChargeIntentResponses/ListChargeIntentsResponse`` or a ``NetworkingError``.
    public static func getAllChargeIntents(page: Int? = nil, perPage: Int? = nil, completionHandler: @escaping @Sendable (ChargeIntentResponses.ListChargeIntentsResponse?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getAllChargeIntents(perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ChargeIntentResponses.ListChargeIntentsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getChargeIntentAsync(_:)``.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent to retrieve.
    ///   - completionHandler: Called with the matching ``FrameObjects/ChargeIntent`` or a ``NetworkingError``.
    public static func getChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.getChargeIntent(intentId: intentId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``updateChargeIntentAsync(_:request:)``.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent to update.
    ///   - request: The fields to update on the charge intent.
    ///   - completionHandler: Called with the updated ``FrameObjects/ChargeIntent`` or a ``NetworkingError``.
    public static func updateChargeIntent(intentId: String, request: ChargeIntentsRequests.UpdateChargeIntentRequest, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        let endpoint = ChargeIntentEndpoints.updateChargeIntent(intentId: intentId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``voidRemainingChargeIntentAsync(_:)``.
    ///
    /// - Parameters:
    ///   - intentId: The unique identifier of the charge intent whose remaining authorisation should be voided.
    ///   - completionHandler: Called with the updated ``FrameObjects/ChargeIntent`` or a ``NetworkingError``.
    public static func voidRemainingChargeIntent(intentId: String, completionHandler: @escaping @Sendable (FrameObjects.ChargeIntent?, NetworkingError?) -> Void) {
        guard !intentId.isEmpty else { return completionHandler(nil, nil) }
        let endpoint = ChargeIntentEndpoints.voidRemainingChargeIntent(intentId: intentId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.ChargeIntent.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
