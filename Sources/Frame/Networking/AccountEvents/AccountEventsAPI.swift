//
//  AccountEventsAPI.swift
//  Frame-iOS
//

import Foundation

/// Calls the account events endpoint. Internal only — integrators never call this directly, the
/// SDK emits its own diagnostic events via ``AccountEventQueue``.
enum AccountEventsAPI {

    /// Submits a batch of events to the backend.
    ///
    /// Authenticates with `.publishableOnly` regardless of any active onboarding session: the
    /// endpoint only ever accepts `pk_`, the event already names the end-user account by
    /// `account_id` in the body, and publishable-only keeps delivery working whether or not
    /// onboarding happens to be in progress when the event fires.
    static func record(_ events: [AccountEventsRequests.Event]) async -> (AccountEventsRequests.RecordResponse?, NetworkingError?) {
        let request = AccountEventsRequests.RecordRequest(events: events)
        guard let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request) else {
            return (nil, NetworkingError.unknownError)
        }

        let data: Data?
        let error: NetworkingError?
        do {
            (data, error) = try await FrameNetworking.shared.performDataTask(
                endpoint: AccountEventsEndpoints.record,
                requestBody: requestBody,
                auth: .publishableOnly
            )
        } catch {
            return (nil, NetworkingError.unknownError)
        }

        guard let data,
              let decoded = try? FrameNetworking.shared.jsonDecoder.decode(
                  AccountEventsRequests.RecordResponse.self, from: data
              ) else {
            return (nil, error ?? NetworkingError.unknownError)
        }
        return (decoded, error)
    }
}
