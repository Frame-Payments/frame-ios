//
//  CustomerIdentity.swift
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
    
    public enum VerificationCheckStatus: String, Codable, Sendable, Equatable {
        case passed
        case failed
    }
    
    public struct IdentificationDocuments: Codable, Sendable, Equatable {
        public let frontDocumentAttached: Bool
        public let backDocumentAttached: Bool
        public let selfieAttached: Bool
    }
    
    public struct IdentificationData: Codable, Sendable, Equatable {
        public let firstName: String?
        public let lastName: String?
        public let middleName: String?
        public let dateOfBirth: String?
        public let licenseNumber: String?
        public let state: String?
        public let expirationDate: String?
        public let address: String?
        
        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case middleName = "middle_name"
            case dateOfBirth = "date_of_birth"
            case licenseNumber = "license_number"
            case expirationDate = "expiration_date"
            case state, address
        }
    }
    
    public struct VerificationChecks: Codable, Sendable, Equatable {
        public let idPhotoFaceMatch: VerificationCheckStatus
        public let idAgeOver18: VerificationCheckStatus
        public let idNotExpired: VerificationCheckStatus
        public let idTamperDetection: VerificationCheckStatus
        
        enum CodingKeys: String, CodingKey {
            case idPhotoFaceMatch = "id_photo_face_match"
            case idAgeOver18 = "id_age_over_18"
            case idNotExpired = "id_not_expired"
            case idTamperDetection = "id_tamper_detection"
        }
    }
    
    public struct CustomerIdentity: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let status: CustomerIdentityStatus
        public let verificationURL: String?
        public let object: String?
        public let created: Int
        public let updated: Int
        public let pending: Int?
        public let verified: Int?
        public let failed: Int?
        public let documents: IdentificationDocuments?
        public let provider: String?
        public let providerReference: String?
        public let extractedData: IdentificationData?
        public let verificationChecks: VerificationChecks?
        public let customer: Customer?

        init(id: String, status: CustomerIdentityStatus, verificationURL: String?, object: String?, created: Int, updated: Int, pending: Int?, verified: Int?, failed: Int?, documents: IdentificationDocuments?, provider: String?, providerReference: String?, extractedData: IdentificationData?, verificationChecks: VerificationChecks?, customer: Customer?) {
            self.id = id
            self.status = status
            self.verificationURL = verificationURL
            self.object = object
            self.created = created
            self.updated = updated
            self.pending = pending
            self.verified = verified
            self.failed = failed
            self.documents = documents
            self.provider = provider
            self.providerReference = providerReference
            self.extractedData = extractedData
            self.verificationChecks = verificationChecks
            self.customer = customer
        }
        
        public enum CodingKeys: String, CodingKey {
            case id, status, object, created, updated, pending, verified, failed, documents, provider, customer
            case verificationURL = "verification_url"
            case providerReference = "provider_reference"
            case extractedData = "extracted_data"
            case verificationChecks = "verification_checks"
        }
    }
}
