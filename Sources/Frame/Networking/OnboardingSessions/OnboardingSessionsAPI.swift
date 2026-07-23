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
/// - Note: `POST /v1/onboarding_sessions` accepts a **publishable key** (`pk_`), so the onboarding
///   flow can mint its own account-scoped session on-device without a secret key — see
///   ``createOnboardingSessionWithPublishableKey(request:)``. The public
///   ``createOnboardingSession(request:)`` methods below default to the configured key (typically
///   `sk_` in the example app) and remain for backward compatibility; production integrations that
///   mint from their own backend hand the resulting `onb_sess_…` to ``OnboardingContainerView`` as
///   its `clientSecret`.
public class OnboardingSessionsAPI: OnboardingSessionsProtocol, @unchecked Sendable {

    /// Mints an onboarding session using the SDK's **publishable key** (`pk_`), the client-safe
    /// credential accepted by `POST /v1/onboarding_sessions`. The onboarding flow calls this to
    /// bind itself to a freshly-created account so subsequent requests (e.g. IDV) authenticate as
    /// the session rather than falling back to the configured key. Not deprecated — unlike the
    /// public `createOnboardingSession(request:)`, this never sends a secret key.
    ///
    /// - Parameter request: The request body specifying the account and onboarding steps.
    /// - Returns: A tuple containing the decoded onboarding session and any networking error encountered.
    public static func createOnboardingSessionWithPublishableKey(request: OnboardingSessionRequest.CreateOnboardingSessionRequest) async throws -> (OnboardingSessionResponses.OnboardingSession?, NetworkingError?) {
        let endpoint = OnboardingSessionEndpoints.createOnboardingSession
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(OnboardingSessionResponses.OnboardingSession.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

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
