//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

public struct GeofencesResponse: Codable {
    public let data: [Geofence]
}

public struct GeoComplianceStatusResponse: Codable {
    public let status: GeoComplianceStatus
    public let reason: GeoComplianceBlockReason?
    public let geofence: GeoComplianceGeofenceSummary?
    public let sonarSessionId: String?
    public let evaluatedAt: Int

    enum CodingKeys: String, CodingKey {
        case status
        case reason
        case geofence
        case sonarSessionId = "sonar_session_id"
        case evaluatedAt = "evaluated_at"
    }
}

public enum GeoComplianceStatus: String, Codable {
    case clear
    case blocked
    case unknown
}

public enum GeoComplianceBlockReason: String, Codable {
    case restrictedTerritory = "restricted_territory"
    case vpnDetected = "vpn_detected"
    case noLocationData = "no_location_data"
}

public struct GeoComplianceGeofenceSummary: Codable {
    public let id: String
    public let name: String
}

