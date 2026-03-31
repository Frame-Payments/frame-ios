//
//  GeocomplianceAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation
import Frame

protocol GeocomplianceProtocol {
    // async/await
    static func listGeofences() async throws -> (GeofencesResponse?, NetworkingError?)
    static func getAccountGeoComplianceStatus(accountId: String) async throws -> (GeoComplianceStatusResponse?, NetworkingError?)
    
    // completionHandler
    static func listGeofences(completionHandler: @escaping @Sendable (GeofencesResponse?, NetworkingError?) -> Void)
    static func getAccountGeoComplianceStatus(accountId: String, completionHandler: @escaping @Sendable (GeoComplianceStatusResponse?, NetworkingError?) -> Void)
}

public final class GeocomplianceAPI: GeocomplianceProtocol, @unchecked Sendable {
   
    public static func listGeofences() async throws -> (GeofencesResponse?, NetworkingError?) {
        let endpoint = GeocomplianceEndpoints.listGeofences

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(GeofencesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    public static func getAccountGeoComplianceStatus(accountId: String) async throws -> (GeoComplianceStatusResponse?, NetworkingError?) {
        let endpoint = GeocomplianceEndpoints.accountGeoCompliance(accountId: accountId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(GeoComplianceStatusResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //completionHandler
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

