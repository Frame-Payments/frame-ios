//
//  GeocomplianceObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

/// The geometric shape used to define a geofence boundary.
public enum GeofenceType: String, Codable {
    /// A geofence defined by an ordered set of coordinate vertices forming a polygon.
    case polygon
    /// A geofence defined by a centre point and a radius.
    case circle
}

/// The spatial event that triggers a geofence rule.
public enum GeofenceRuleTrigger: String, Codable {
    /// Fired when a device crosses into the geofence boundary.
    case enter
    /// Fired when a device crosses out of the geofence boundary.
    case exit
    /// Fired when a device remains inside the geofence for a configured duration.
    case dwell
}

/// The action taken when a geofence rule is triggered.
public enum GeofenceRuleActionType: String, Codable {
    /// Prevents a transaction from being processed while the trigger condition is active.
    case blockTransaction = "block_transaction"
}

/// A rule that pairs a spatial trigger with the action to perform when that trigger fires.
public struct GeofenceRule: Codable {
    /// The spatial event that activates this rule.
    public let triggerOn: GeofenceRuleTrigger
    /// The action taken when `triggerOn` fires.
    public let actionType: GeofenceRuleActionType

    enum CodingKeys: String, CodingKey {
        case triggerOn = "trigger_on"
        case actionType = "action_type"
    }
}

/// A geofence object returned by the Frame geocompliance API, representing a named geographic boundary and its associated enforcement rules.
public struct Geofence: Codable {
    /// Unique identifier for the geofence.
    public let id: String
    /// The API object type string (e.g. `"geofence"`).
    public let object: String
    /// Human-readable display name for the geofence.
    public let name: String
    /// The geometric shape that defines the geofence boundary.
    public let geofenceType: GeofenceType
    /// Whether the geofence is currently enforced.
    public let active: Bool
    /// The set of rules that govern what happens when a device interacts with this geofence.
    public let geofenceRules: [GeofenceRule]

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case name
        case active
        case geofenceType = "geofence_type"
        case geofenceRules = "geofence_rules"
    }
}
