//
//  ConfigurationResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation

public class ConfigurationResponses {
    public struct GetConfigurationResponse: Codable {
        let appId: String?
        let teamId: String?
        
        enum CodingKeys: String, CodingKey {
            case appId = "app_id"
            case teamId = "team_id"
        }
    }
}
