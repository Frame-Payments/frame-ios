//
//  AccountEventsRequests.swift
//  Frame-iOS
//

import Foundation

/// Request body and response model namespace for the account events API.
final class AccountEventsRequests {

    /// A single diagnostic/telemetry event describing something that happened to an end user's
    /// account during an SDK flow (e.g. an attestation failure).
    struct Event: Encodable {
        let accountId: String
        let name: String
        let screen: String
        let platform: String
        let sdkVersion: String
        let hostSDKVersion: String?
        let occurredAt: String
        let detail: String?

        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case name
            case screen
            case platform
            case sdkVersion = "sdk_version"
            case hostSDKVersion = "host_sdk_version"
            case occurredAt = "occurred_at"
            case detail
        }
    }

    /// Request body for `POST /v1/client/account_events`. Always a batch, even for one event.
    struct RecordRequest: Encodable {
        let events: [Event]
    }

    /// Response body for `POST /v1/client/account_events`.
    struct RecordResponse: Decodable {
        /// Number of events accepted from the batch.
        let recorded: Int
        /// Per-event rejections, by index into the submitted batch. Never retry these.
        let rejected: [Rejection]
    }

    /// One rejected event from a batch, identified by its index in the submitted request.
    struct Rejection: Decodable {
        let index: Int
        let name: String
        let error: String
    }
}
