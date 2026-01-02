//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/30/25.
//

import Foundation

class SessionRequests {
    
    struct SessionMetadata: Encodable, Sendable {
        let platform: String = "iOS"
        let appVersion: String
        let deviceId: String
        
        init(appVersion: String, deviceId: String) {
            self.appVersion = appVersion
            self.deviceId = deviceId
        }
        
        enum CodingKeys: String, CodingKey {
            case platform
            case appVersion = "app_version"
            case deviceId = "device_id"
        }
    }
    
    struct CreateOnboardingSession: Encodable, Sendable {
        let customerId: String
        let metadata: SessionMetadata
        let entryPoint: String = "signup"
        let components: Components
        
        init(customerId: String, metadata: SessionMetadata, components: Components) {
            self.customerId = customerId
            self.metadata = metadata
            self.components = components
        }
        
        enum CodingKeys: String, CodingKey {
            case metadata, components
            case customerId = "customer_id"
            case entryPoint = "entry_point"
        }
    }
    
    struct CancelOnboardingSession: Encodable, Sendable {
        let status: SessionStatus = .canceled
    }
}
