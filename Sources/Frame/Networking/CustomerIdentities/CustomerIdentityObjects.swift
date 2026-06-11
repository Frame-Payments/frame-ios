//
//  CustomerIdentity.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

extension FrameObjects {
    /// Represents the overall verification status of a customer identity record.
    public enum CustomerIdentityStatus: String, Codable, Sendable {
        /// The identity verification process has not been completed.
        case incomplete
        /// The identity has been submitted and is awaiting review.
        case pending
        /// The identity has been successfully verified.
        case verified
        /// The identity verification process did not pass.
        case failed
    }

    /// Indicates whether an individual verification check passed or failed.
    public enum VerificationCheckStatus: String, Codable, Sendable, Equatable {
        /// The verification check was successful.
        case passed
        /// The verification check did not pass.
        case failed
    }

    /// Tracks which identification document images have been attached to a verification session.
    public struct IdentificationDocuments: Codable, Sendable, Equatable {
        /// Whether the front of the ID document has been uploaded.
        public let frontDocumentAttached: Bool
        /// Whether the back of the ID document has been uploaded.
        public let backDocumentAttached: Bool
        /// Whether a selfie image has been uploaded for face-match verification.
        public let selfieAttached: Bool
    }

    /// Personal and document data extracted from a customer's submitted identification.
    public struct IdentificationData: Codable, Sendable, Equatable {
        /// The customer's first name as it appears on their ID.
        public let firstName: String?
        /// The customer's last name as it appears on their ID.
        public let lastName: String?
        /// The customer's middle name as it appears on their ID, if present.
        public let middleName: String?
        /// The customer's date of birth in ISO 8601 format.
        public let dateOfBirth: String?
        /// The driver's license or ID document number.
        public let licenseNumber: String?
        /// The US state that issued the identification document.
        public let state: String?
        /// The expiration date of the identification document.
        public let expirationDate: String?
        /// The address printed on the identification document.
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

    /// Results of the automated verification checks run against a submitted identity document.
    public struct VerificationChecks: Codable, Sendable, Equatable {
        /// Whether the selfie photo matches the face on the ID document.
        public let idPhotoFaceMatch: VerificationCheckStatus
        /// Whether the ID document confirms the customer is 18 years of age or older.
        public let idAgeOver18: VerificationCheckStatus
        /// Whether the ID document is currently within its validity period.
        public let idNotExpired: VerificationCheckStatus
        /// Whether the ID document shows no signs of tampering or forgery.
        public let idTamperDetection: VerificationCheckStatus

        enum CodingKeys: String, CodingKey {
            case idPhotoFaceMatch = "id_photo_face_match"
            case idAgeOver18 = "id_age_over_18"
            case idNotExpired = "id_not_expired"
            case idTamperDetection = "id_tamper_detection"
        }
    }

    /// A customer identity verification record returned by the Frame API.
    public struct CustomerIdentity: Codable, Sendable, Identifiable, Equatable {
        /// The unique identifier for this identity verification record.
        public let id: String
        /// The current verification status of the identity record.
        public let status: CustomerIdentityStatus
        /// A URL the customer can visit to complete the identity verification flow.
        public let verificationURL: String?
        /// The API object type string, typically `"customer_identity"`.
        public let object: String?
        /// Unix timestamp (seconds) when this record was created.
        public let created: Int
        /// Unix timestamp (seconds) when this record was last updated.
        public let updated: Int
        /// Unix timestamp (seconds) when the record entered the `pending` state, if applicable.
        public let pending: Int?
        /// Unix timestamp (seconds) when the record was successfully verified, if applicable.
        public let verified: Int?
        /// Unix timestamp (seconds) when the record entered the `failed` state, if applicable.
        public let failed: Int?
        /// The document images that have been attached to this verification session.
        public let documents: IdentificationDocuments?
        /// The third-party identity verification provider used for this record.
        public let provider: String?
        /// A reference identifier from the verification provider for this record.
        public let providerReference: String?
        /// Personal and document data extracted by the verification provider.
        public let extractedData: IdentificationData?
        /// Results of the automated checks run against the submitted documents.
        public let verificationChecks: VerificationChecks?
        /// The customer associated with this identity verification record.
        public let customer: Customer?

        /// Creates a new `CustomerIdentity` instance with the supplied field values.
        /// - Parameters:
        ///   - id: Unique identifier for the record.
        ///   - status: Current verification status.
        ///   - verificationURL: URL for the customer to complete verification.
        ///   - object: API object type string.
        ///   - created: Unix timestamp of record creation.
        ///   - updated: Unix timestamp of the last update.
        ///   - pending: Unix timestamp when the record became pending, if applicable.
        ///   - verified: Unix timestamp when verification succeeded, if applicable.
        ///   - failed: Unix timestamp when verification failed, if applicable.
        ///   - documents: Attached identification document images.
        ///   - provider: Name of the third-party verification provider.
        ///   - providerReference: Provider-issued reference for this verification.
        ///   - extractedData: Data extracted from the submitted identification.
        ///   - verificationChecks: Results of automated document checks.
        ///   - customer: Customer associated with this record.
        init(id: String, status: CustomerIdentityStatus, verificationURL: String?, object: String?, created: Int, updated: Int, pending: Int?, verified: Int?, failed: Int?, documents: IdentificationDocuments? = nil, provider: String? = nil, providerReference: String? = nil, extractedData: IdentificationData? = nil, verificationChecks: VerificationChecks? = nil, customer: Customer? = nil) {
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
