//
//  CapabilityObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

extension FrameObjects {
    
    public struct CapabilityRequirement: Codable, Sendable, Equatable {
        public let id: String
        public let object: String
        public let type: String
        public let status: String
        public let source: String?
        
        enum CodingKeys: String, CodingKey {
            case id, object, type, status, source
        }
    }
    
    public struct Capability: Codable, Sendable, Equatable {
        public let id: String
        public let object: String
        public let name: String
        public let status: String
        public let disabledReason: String?
        public let requirements: [CapabilityRequirement]?
        public let createdAt: Int
        public let updatedAt: Int
        
        enum CodingKeys: String, CodingKey {
            case id, object, name, status, requirements
            case disabledReason = "disabled_reason"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
}
