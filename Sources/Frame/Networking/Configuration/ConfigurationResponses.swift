//
//  ConfigurationResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation

public class ConfigurationResponses {
    public struct GetEvervaultConfigurationResponse: Codable {
        let appId: String?
        let teamId: String?
        
        enum CodingKeys: String, CodingKey {
            case appId = "app_id"
            case teamId = "team_id"
        }
    }
    
    public struct GetSiftConfigurationResponse: Codable {
        let accountId: String?
        let beaconKey: String?
        
        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case beaconKey = "beacon_key"
        }
    }
}
