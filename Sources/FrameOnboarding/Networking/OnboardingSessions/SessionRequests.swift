//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/30/25.
//

import Foundation

class SessionRequests {
    struct CreateOnboardingSession: Encodable, Sendable {
        let customerId: String
        let metadata: SessionMetadata
        let entryPoint: String = "signup"
        let components: SessionComponents
        
        init(customerId: String, metadata: SessionMetadata, components: SessionComponents) {
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
    
    struct UpdatePayoutMethodRequest: Encodable, Sendable {
        let payoutMethodId: String
        
        init(payoutMethodId: String) {
            self.payoutMethodId = payoutMethodId
        }
        
        enum CodingKeys: String, CodingKey {
            case payoutMethodId = "payout_method_id"
        }
    }
    
    struct CancelOnboardingSession: Encodable, Sendable {
        let status: SessionStatus = .canceled
    }
}
