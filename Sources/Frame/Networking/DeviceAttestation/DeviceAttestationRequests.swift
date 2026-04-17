//
//  DeviceAttestationRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/14/26.
//

import Foundation

public class DeviceAttestationRequests {

    public struct AttestRequest: Encodable {
        let keyId: String
        let attestationObject: String
        let challenge: String

        enum CodingKeys: String, CodingKey {
            case keyId = "key_id"
            case attestationObject = "attestation_object"
            case challenge
        }
    }

    public struct ChallengeResponse: Decodable {
        public let challenge: String
    }

    public struct AttestResponse: Decodable {
        public let status: String
        public let keyId: String

        enum CodingKeys: String, CodingKey {
            case status
            case keyId = "key_id"
        }
    }
}
