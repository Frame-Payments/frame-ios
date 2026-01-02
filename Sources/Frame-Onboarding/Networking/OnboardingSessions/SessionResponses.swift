//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/30/25.
//

import Foundation

class SessionResponses {
    struct ListSessionsResponse: Codable {
        public let data: [OnboardingSession]?
    }
}
