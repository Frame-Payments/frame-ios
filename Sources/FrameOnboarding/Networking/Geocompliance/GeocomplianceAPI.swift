//
//  GeocomplianceAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation
import Frame

/// Internal protocol defining the geo-compliance API surface, covering both async/await and completion-handler variants.
protocol GeocomplianceProtocol {
    // async/await
    /// Returns the list of configured geofences.
    static func listGeofences() async throws -> (GeofencesResponse?, NetworkingError?)
    /// Returns the geo-compliance status for the specified account.
    static func getAccountGeoComplianceStatus(accountId: String) async throws -> (GeoComplianceStatusResponse?, NetworkingError?)

    // completionHandler
    /// Completion-handler variant of `listGeofences()`.
    static func listGeofences(completionHandler: @escaping @Sendable (GeofencesResponse?, NetworkingError?) -> Void)
    /// Completion-handler variant of `getAccountGeoComplianceStatus(accountId:)`.
    static func getAccountGeoComplianceStatus(accountId: String, completionHandler: @escaping @Sendable (GeoComplianceStatusResponse?, NetworkingError?) -> Void)
}

/// Manages geo-compliance resources, providing methods to retrieve geofences and account geo-compliance status.
public final class GeocomplianceAPI: GeocomplianceProtocol, @unchecked Sendable {

    /// Returns the list of configured geofences.
    ///
    /// - Returns: A tuple containing the decoded ``GeofencesResponse`` on success, or a ``NetworkingError`` on failure.
    public static func listGeofences() async throws -> (GeofencesResponse?, NetworkingError?) {
        let endpoint = GeocomplianceEndpoints.listGeofences

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(GeofencesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Returns the geo-compliance status for the specified account.
    ///
    /// - Parameter accountId: The unique identifier of the account to query.
    /// - Returns: A tuple containing the decoded ``GeoComplianceStatusResponse`` on success, or a ``NetworkingError`` on failure.
    public static func getAccountGeoComplianceStatus(accountId: String) async throws -> (GeoComplianceStatusResponse?, NetworkingError?) {
        let endpoint = GeocomplianceEndpoints.accountGeoCompliance(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(GeoComplianceStatusResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    // completionHandler

    /// Completion-handler variant of `listGeofences()`.
    ///
    /// - Parameter completionHandler: Called with the decoded ``GeofencesResponse``, or a ``NetworkingError`` on failure.
    public static func listGeofences(completionHandler: @escaping @Sendable (GeofencesResponse?, Frame.NetworkingError?) -> Void) {
        let endpoint = GeocomplianceEndpoints.listGeofences
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(GeofencesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    /// Completion-handler variant of `getAccountGeoComplianceStatus(accountId:)`.
    ///
    /// - Parameters:
    ///   - accountId: The unique identifier of the account to query.
    ///   - completionHandler: Called with the decoded ``GeoComplianceStatusResponse``, or a ``NetworkingError`` on failure.
    public static func getAccountGeoComplianceStatus(accountId: String, completionHandler: @escaping @Sendable (GeoComplianceStatusResponse?, Frame.NetworkingError?) -> Void) {
        let endpoint = GeocomplianceEndpoints.accountGeoCompliance(accountId: accountId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(GeoComplianceStatusResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}

