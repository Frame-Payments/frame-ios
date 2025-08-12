//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

extension FrameObjects {
    public enum CustomerIdentityStatus: String, Codable, Sendable {
        case incomplete
        case pending
        case verified
        case failed
    }
    
    public struct CustomerIdentity: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let status: CustomerIdentityStatus?
        public let verificationURL: String?
        public let object: String?
        public let created: Int?
        public let updated: Int?
        public let pending: Int?
        public let verified: Int?
        public let failed: Int?
        
        public init(id: String, status: CustomerIdentityStatus?, verificationURL: String?, object: String?, created: Int?, updated: Int?, pending: Int?, verified: Int?, failed: Int?) {
            self.id = id
            self.status = status
            self.verificationURL = verificationURL
            self.object = object
            self.created = created
            self.updated = updated
            self.pending = pending
            self.verified = verified
            self.failed = failed
        }
//
        public enum CodingKeys: String, CodingKey {
            case id
            case status
            case verificationURL = "verification_url"
            case object
            case created
            case updated
            case pending
            case verified
            case failed
        }
    }
}
