//
//  OnboardingSessionsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 6/26/26.
//

import Foundation

/// Internal protocol defining the onboarding-sessions API surface, used for mock testing.
protocol OnboardingSessionsProtocol {
    // async/await
    static func createOnboardingSession(request: OnboardingSessionRequest.CreateOnboardingSessionRequest) async throws -> (OnboardingSessionResponses.OnboardingSession?, NetworkingError?)

    // completionHandler
    static func createOnboardingSession(request: OnboardingSessionRequest.CreateOnboardingSessionRequest, completionHandler: @escaping @Sendable (OnboardingSessionResponses.OnboardingSession?, NetworkingError?) -> Void)
}

/// Creates onboarding sessions in the Frame SDK.
///
/// - Warning: Creating an onboarding session is a **server-only** operation. It authenticates with
///   your secret key (`sk_`), which must never ship inside an app binary. This API is provided so
///   the example app can mint a session token for end-to-end testing — it is **not** the intended
///   production path. Production integrations mint the `onb_sess_…` token from their backend
///   (`POST /v1/onboarding_sessions`) and hand it to ``OnboardingContainerView`` as its `clientSecret`.
public class OnboardingSessionsAPI: OnboardingSessionsProtocol, @unchecked Sendable {

    //MARK: Methods using async/await

    /// Creates an onboarding session and returns its `onb_sess_…` client secret.
    ///
    /// - Parameter request: The request body specifying the account and onboarding steps.
    /// - Returns: A tuple containing the decoded onboarding session and any networking error encountered.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createOnboardingSession(request: OnboardingSessionRequest.CreateOnboardingSessionRequest) async throws -> (OnboardingSessionResponses.OnboardingSession?, NetworkingError?) {
        let endpoint = OnboardingSessionEndpoints.createOnboardingSession
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(OnboardingSessionResponses.OnboardingSession.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //MARK: Methods using completion handler

    /// Completion-handler variant of `createOnboardingSession(request:)`.
    ///
    /// - Parameters:
    ///   - request: The request body specifying the account and onboarding steps.
    ///   - completionHandler: Called with the decoded onboarding session and any networking error encountered.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createOnboardingSession(request: OnboardingSessionRequest.CreateOnboardingSessionRequest, completionHandler: @escaping @Sendable (OnboardingSessionResponses.OnboardingSession?, NetworkingError?) -> Void) {
        let endpoint = OnboardingSessionEndpoints.createOnboardingSession
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(OnboardingSessionResponses.OnboardingSession.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
