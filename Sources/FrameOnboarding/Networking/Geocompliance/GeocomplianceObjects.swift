//
//  GeocomplianceObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//

import Foundation

public enum GeofenceType: String, Codable {
    case polygon
    case circle
}

public enum GeofenceRuleTrigger: String, Codable {
    case enter
    case exit
    case dwell
}

public enum GeofenceRuleActionType: String, Codable {
    case blockTransaction = "block_transaction"
}

public struct GeofenceRule: Codable {
    public let triggerOn: GeofenceRuleTrigger
    public let actionType: GeofenceRuleActionType

    enum CodingKeys: String, CodingKey {
        case triggerOn = "trigger_on"
        case actionType = "action_type"
    }
}

public struct Geofence: Codable {
    public let id: String
    public let object: String
    public let name: String
    public let geofenceType: GeofenceType
    public let active: Bool
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
