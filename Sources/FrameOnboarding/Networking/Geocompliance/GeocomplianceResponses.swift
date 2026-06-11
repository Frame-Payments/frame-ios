//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

/// Response model namespace for Geofences API calls.
///
/// Wraps the paginated list of ``Geofence`` objects returned when fetching all configured geofences.
public struct GeofencesResponse: Codable {
    /// The collection of geofences returned by the API.
    public let data: [Geofence]
}

/// Response model namespace for Geo Compliance Status API calls.
///
/// Contains the result of a geo-compliance check for the current user session, including
/// the overall status, any block reason, the matched geofence, and session metadata.
public struct GeoComplianceStatusResponse: Codable {
    /// The overall compliance status for the evaluated session.
    public let status: GeoComplianceStatus
    /// The reason the session was blocked, if applicable.
    public let reason: GeoComplianceBlockReason?
    /// A summary of the geofence that was matched during evaluation, if any.
    public let geofence: GeoComplianceGeofenceSummary?
    /// The Sonar session identifier associated with this compliance check.
    public let sonarSessionId: String?
    /// Unix timestamp (in seconds) at which the compliance check was performed.
    public let evaluatedAt: Int

    enum CodingKeys: String, CodingKey {
        case status
        case reason
        case geofence
        case sonarSessionId = "sonar_session_id"
        case evaluatedAt = "evaluated_at"
    }
}

/// The overall result of a geo-compliance evaluation for a user session.
public enum GeoComplianceStatus: String, Codable {
    /// The session passed all geo-compliance checks and is permitted to proceed.
    case clear
    /// The session was blocked due to a geo-compliance violation.
    case blocked
    /// The compliance status could not be determined.
    case unknown
}

/// The specific reason a user session was blocked during a geo-compliance check.
public enum GeoComplianceBlockReason: String, Codable {
    /// The user's location falls within a restricted territory.
    case restrictedTerritory = "restricted_territory"
    /// A VPN or proxy was detected that obscures the user's true location.
    case vpnDetected = "vpn_detected"
    /// Insufficient location data was available to complete the compliance check.
    case noLocationData = "no_location_data"
}

/// A lightweight summary of a geofence returned within a compliance status response.
public struct GeoComplianceGeofenceSummary: Codable {
    /// The unique identifier of the geofence.
    public let id: String
    /// The human-readable name of the geofence.
    public let name: String
}
