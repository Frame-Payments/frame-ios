//
//  FrameAuth.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

// https://docs.framepayments.com/authentication

import SwiftUI
import EvervaultCore
import Sift

// Create Network Request Here That Return Callbacks With User Data, This is the "Router"

// TODO: Add Pagination for Network Request

/// Central networking hub for the Frame SDK, responsible for authenticating and dispatching
/// all HTTP requests to the Frame Payments API.
///
/// Obtain the singleton via ``shared`` and call ``initialize(publishableKey:secretKey:applePayMerchantId:theme:debugMode:)``
/// once at app launch before using any other SDK API. The SDK is publishable-key first: pass your
/// publishable key (`pk_`) and serve any secret key from your backend.
public class FrameNetworking: ObservableObject {
    /// The shared singleton instance used by all SDK components.
    nonisolated(unsafe) public static let shared = FrameNetworking()

    /// Shared JSON encoder used across the SDK.
    public let jsonEncoder = JSONEncoder()
    /// Shared JSON decoder used across the SDK.
    public let jsonDecoder = JSONDecoder()

    var asyncURLSession: URLSessionProtocol = URLSession.shared
    var urlSession: URLSession = URLSession.shared

    private var apiSecretKey: String = "" // Secret key (sk_). Server-only; avoid shipping in an app binary.
    private var apiPublishableKey: String = "" // Publishable key (pk_). Default credential for client-safe endpoints.
    private var debugMode: Bool = false // Print API data on task calls.

    /// Tracks whether the one-time secret-key usage warning has already been emitted.
    private var hasWarnedAboutSecretKeyUsage = false

    /// The active onboarding-session client secret (`onb_sess_…`), if an onboarding flow is in progress.
    ///
    /// While set, every request authenticates with this token instead of `pk_`/`sk_`, scoping the
    /// onboarding flow to a single account (see ``beginOnboardingSession(clientSecret:)``).
    private var onboardingSessionToken: String?

    var isEvervaultConfigured: Bool = false

    /// The active SDK-wide visual theme, applied to all Frame-rendered UI surfaces.
    @MainActor
    public private(set) var globalTheme: FrameTheme = .default

    /// Apple Pay merchant identifier, captured at SDK init and read by every Apple Pay surface.
    public private(set) var applePayMerchantId: String?

    /// Initializes the SDK with a publishable key (`pk_`) and configuration.
    ///
    /// This is the recommended entry point. Call it once, early in the app lifecycle
    /// (e.g. `application(_:didFinishLaunchingWithOptions:)`), before making any other SDK calls.
    ///
    /// The publishable key is the SDK's default credential and is safe to embed in an app
    /// binary. Only pass a secret key (`secretKey:`) if you must call a server-only endpoint
    /// from the app — and prefer serving that key from your own backend instead.
    ///
    /// - Parameters:
    ///   - publishableKey: Your Frame Payments publishable key (`pk_`). Used for all client-safe endpoints.
    ///   - secretKey: Optional secret key (`sk_`). Server-only; avoid shipping it in an app binary. Defaults to `nil`.
    ///   - applePayMerchantId: Optional Apple Pay merchant identifier required to present Apple Pay sheets.
    ///   - theme: Visual theme applied to all Frame SDK UI. Defaults to ``FrameTheme/default``.
    ///   - debugMode: When `true`, request and response bodies are printed to the console. Defaults to `false`.
    public func initialize(publishableKey: String,
                           secretKey: String? = nil,
                           applePayMerchantId: String? = nil,
                           theme: FrameTheme = .default,
                           debugMode: Bool = false) {
        if publishableKey.hasPrefix("sk_") {
            warnSecretKeyMisuse(context: "passed as the publishableKey")
        }
        if let secretKey, !secretKey.isEmpty {
            warnSecretKeyMisuse(context: "configured via secretKey")
        }

        self.apiPublishableKey = publishableKey
        self.apiSecretKey = secretKey ?? ""
        self.applePayMerchantId = applePayMerchantId
        self.debugMode = debugMode

        // Initializes Sift, Sonar Session, and Device Attestation when the SDK is initialized.
        Task {
            await SiftManager.initializeSift()
            await SessionManager.initializeSession()
            _ = try? await DeviceAttestationManager.shared.attestDevice()
        }

        if !isEvervaultConfigured {
            self.configureEvervault()
        }

        // Set global theme
        Task {
            await MainActor.run {
                globalTheme = theme
            }
        }
    }

    /// Initializes the SDK with the provided credentials and configuration.
    ///
    /// - Important: This signature leads with the secret key and is retained only for source
    ///   compatibility. Prefer ``initialize(publishableKey:secretKey:applePayMerchantId:theme:debugMode:)``,
    ///   which is publishable-key first.
    ///
    /// - Parameters:
    ///   - key: Your Frame Payments secret API key. Server-only; avoid shipping it in an app binary.
    ///   - publishableKey: Your Frame Payments publishable key used for client-side-only endpoints.
    ///   - applePayMerchantId: Optional Apple Pay merchant identifier required to present Apple Pay sheets.
    ///   - theme: Visual theme applied to all Frame SDK UI. Defaults to ``FrameTheme/default``.
    ///   - debugMode: When `true`, request and response bodies are printed to the console. Defaults to `false`.
    @available(*, deprecated, message: "Use initialize(publishableKey:secretKey:applePayMerchantId:theme:debugMode:). Secret keys must not ship in an app binary — serve sk_ from your backend.")
    public func initializeWithAPIKey(_ key: String,
                                     publishableKey: String,
                                     applePayMerchantId: String? = nil,
                                     theme: FrameTheme = .default,
                                     debugMode: Bool = false) {
        initialize(publishableKey: publishableKey,
                   secretKey: key,
                   applePayMerchantId: applePayMerchantId,
                   theme: theme,
                   debugMode: debugMode)
    }

    /// Begins an onboarding session, binding all subsequent SDK requests to the given
    /// onboarding-session client secret (`onb_sess_…`).
    ///
    /// The integrator's server creates the onboarding session (`POST /v1/onboarding_sessions`) and
    /// hands the resulting `onb_sess_…` token to the app. While a session is active, every request
    /// authenticates with this token instead of `pk_`/`sk_`, which scopes the flow to a single
    /// account (a bare publishable key would allow cross-account access). Call
    /// ``endOnboardingSession()`` when the onboarding flow completes or is dismissed.
    ///
    /// - Parameter clientSecret: The onboarding-session token (`onb_sess_…`).
    public func beginOnboardingSession(clientSecret: String) {
        if !clientSecret.hasPrefix("onb_sess_") {
            warnOnce(&hasWarnedAboutOnboardingTokenPrefix,
                     "⚠️ Frame: beginOnboardingSession was called with a token that is not an onboarding-session "
                     + "token (onb_sess_…). Onboarding requests authenticate with this value verbatim, so a publishable "
                     + "key, secret key, or charge-intent client secret will not scope the flow to an account and may be "
                     + "rejected. Mint the token from your backend via POST /v1/onboarding_sessions.")
        }
        onboardingSessionToken = clientSecret
    }

    /// Ends the active onboarding session, restoring normal `pk_`/`sk_` authentication.
    public func endOnboardingSession() {
        onboardingSessionToken = nil
    }

    /// Resolves the Bearer token for a request based on its ``FrameAuthMode``.
    ///
    /// While an onboarding session is active (see ``beginOnboardingSession(clientSecret:)``), the
    /// onboarding-session token takes precedence for every request, scoping the flow to one account.
    /// Otherwise, emits a one-time warning the first time the secret key is used, steering
    /// integrators toward serving `sk_` from their backend.
    private func bearerToken(for auth: FrameAuthMode) -> String {
        // An explicit per-call client secret always wins (e.g. a charge intent's client_secret).
        if case .clientSecret(let token) = auth {
            return token
        }

        // During onboarding, every request is authenticated by the onboarding-session token.
        if let onboardingSessionToken {
            return onboardingSessionToken
        }

        switch auth {
        case .publishable:
            if apiPublishableKey.isEmpty {
                warnOnce(&hasMissingPublishableKeyWarned,
                         "⚠️ Frame: a client-safe request was made but no publishable key (pk_) is configured. Call initialize(publishableKey:) first.")
            }
            return apiPublishableKey
        case .secret:
            // A secret key actually leaving the device on a live request is the most actionable
            // misuse; warn on it independently of the init-time configuration warning.
            warnOnce(&hasWarnedAboutSecretKeyRequest,
                     secretKeyWarning(context: "used to authenticate a request from the app"))
            return apiSecretKey
        case .clientSecret:
            // Handled by the early return above; unreachable here.
            return ""
        }
    }

    /// Set once a missing-publishable-key warning has been emitted.
    private var hasMissingPublishableKeyWarned = false

    /// Set once the secret key has been used to authenticate a live request.
    private var hasWarnedAboutSecretKeyRequest = false

    /// Set once a non-`onb_sess_` onboarding token warning has been emitted.
    private var hasWarnedAboutOnboardingTokenPrefix = false

    private func warnSecretKeyMisuse(context: String) {
        warnOnce(&hasWarnedAboutSecretKeyUsage, secretKeyWarning(context: context))
    }

    private func secretKeyWarning(context: String) -> String {
        "⚠️ Frame: a secret key (sk_) was \(context). Secret keys grant full merchant privileges and must never ship in an app binary, where they can be extracted by reverse-engineering. Serve sk_ from your backend and pass only your publishable key (pk_) to the SDK."
    }

    /// Prints `message` to the console the first time `flag` is `false`, then sets it `true`.
    private func warnOnce(_ flag: inout Bool, _ message: String) {
        guard !flag else { return }
        flag = true
        print(message)
    }

    /// The Sonar session stored for `accountId`, if any.
    ///
    /// Prefer `SessionManager.shared.ensureSession(accountId:)` on a payment path — this only reads
    /// what is already persisted and will return `nil` if no session has been established yet.
    func currentSonarSessionId(accountId: String? = nil) -> String? {
        SonarSessionStorage.currentSessionId(accountId: accountId)
    }

    // Async/Await
    /// Performs an authenticated HTTP data task against a Frame API endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The ``FrameNetworkingEndpoints`` value that specifies the URL path, HTTP method, and query items.
    ///   - requestBody: Optional JSON-encoded body data to include in the request.
    ///   - auth: Which credential authenticates the request. Defaults to ``FrameAuthMode/secret``.
    /// - Returns: A tuple of the raw response `Data` (if any) and a ``NetworkingError`` (if the request failed).
    public func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, auth: FrameAuthMode = .secret) async throws -> (Data?, NetworkingError?) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return (nil, nil) }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue
        if endpoint.httpMethod == .POST || endpoint.httpMethod == .PATCH {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = requestBody
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }

        urlRequest.setValue("Bearer \(bearerToken(for: auth))", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(ipAddress, forHTTPHeaderField: "ip_address")
        }

        do {
            let (data, response) = try await asyncURLSession.data(for: urlRequest)
            if debugMode {
                print("\nAPI Endpoint: " + (response.url?.absoluteString ?? ""))
                printDataForTesting(data: requestBody)
                printDataForTesting(data: data)
            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                return (data, NetworkingError.serverError(statusCode: httpResponse.statusCode, errorDescription: returnErrorString(data: data)))
            }
            return (data, nil)
        } catch URLError.cannotFindHost {
            return (nil, NetworkingError.invalidURL)
        } catch URLError.cannotDecodeRawData {
            return (nil, NetworkingError.decodingFailed)
        } catch {
            return (nil, NetworkingError.unknownError)
        }
    }

    /// Performs an authenticated multipart/form-data upload to a Frame API endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The ``FrameNetworkingEndpoints`` value that specifies the URL path, HTTP method, and query items.
    ///   - filesToUpload: An array of ``FileUpload`` values describing each file part to include in the request.
    ///   - auth: Which credential authenticates the request. Defaults to ``FrameAuthMode/secret``.
    /// - Returns: A tuple of the raw response `Data` (if any) and a ``NetworkingError`` (if the request failed).
    public func performMultipartDataTask(endpoint: FrameNetworkingEndpoints, filesToUpload: [FileUpload], auth: FrameAuthMode = .secret) async throws -> (Data?, NetworkingError?) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return (nil, nil) }

        let multipart = MultipartFormDataBuilder()

        filesToUpload.forEach { file in
            multipart.addFile(
                fieldName: file.fieldName.rawValue,
                fileName: file.fileName,
                mimeType: file.mimeType,
                fileData: file.data
            )
        }

        let body = multipart.build()

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue

        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }

        urlRequest.httpBody = body
        urlRequest.setValue(multipart.contentTypeHeader, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        urlRequest.setValue("Bearer \(bearerToken(for: auth))", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(ipAddress, forHTTPHeaderField: "ip_address")
        }

        do {
            let (data, response) = try await asyncURLSession.data(for: urlRequest)
            if debugMode {
                print("\nAPI Endpoint: " + (response.url?.absoluteString ?? ""))
                printDataForTesting(data: body)
                printDataForTesting(data: data)
            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                return (nil, NetworkingError.serverError(statusCode: httpResponse.statusCode, errorDescription: returnErrorString(data: data)))
            }
            return (data, nil)
        } catch URLError.cannotFindHost {
            return (nil, NetworkingError.invalidURL)
        } catch URLError.cannotDecodeRawData {
            return (nil, NetworkingError.decodingFailed)
        } catch {
            return (nil, NetworkingError.unknownError)
        }
    }

    // Completion Handler
    /// Completion-handler variant of ``performDataTask(endpoint:requestBody:auth:)``.
    ///
    /// - Parameters:
    ///   - endpoint: The ``FrameNetworkingEndpoints`` value that specifies the URL path, HTTP method, and query items.
    ///   - requestBody: Optional JSON-encoded body data to include in the request.
    ///   - auth: Which credential authenticates the request. Defaults to ``FrameAuthMode/secret``.
    ///   - completion: Called on task completion with the raw `Data`, the `URLResponse`, and an optional ``NetworkingError``.
    public func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, auth: FrameAuthMode = .secret, completion: @escaping @Sendable (Data?, URLResponse?, NetworkingError?) -> Void) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return completion(nil, nil, nil) }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue
        if endpoint.httpMethod == .POST || endpoint.httpMethod == .PATCH {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = requestBody
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }

        urlRequest.setValue("Bearer \(bearerToken(for: auth))", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")

        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(ipAddress, forHTTPHeaderField: "ip_address")
        }

        urlSession.dataTask(with: urlRequest) { data, response, error in
            var networkingError: NetworkingError?

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                networkingError = NetworkingError.serverError(statusCode: httpResponse.statusCode, errorDescription: error?.localizedDescription ?? "")
            } else if data == nil {
                networkingError = NetworkingError.noData
            } else if let urlError = error as? URLError {
                switch urlError {
                case URLError.cannotFindHost:
                    networkingError = NetworkingError.invalidURL
                case URLError.cannotDecodeRawData:
                    networkingError = NetworkingError.decodingFailed
                default:
                    networkingError = NetworkingError.unknownError
                }
            }

            completion(data, response, networkingError)
        }.resume()
    }

    /// Completion-handler variant of ``performMultipartDataTask(endpoint:filesToUpload:)``.
    ///
    /// - Parameters:
    ///   - endpoint: The ``FrameNetworkingEndpoints`` value that specifies the URL path, HTTP method, and query items.
    ///   - filesToUpload: An array of ``FileUpload`` values describing each file part to include in the request.
    ///   - auth: Which credential authenticates the request. Defaults to ``FrameAuthMode/secret``.
    ///   - completion: Called on task completion with the raw `Data`, the `URLResponse`, and an optional ``NetworkingError``.
    public func performMultipartDataTask(endpoint: FrameNetworkingEndpoints, filesToUpload: [FileUpload], auth: FrameAuthMode = .secret, completion: @escaping @Sendable (Data?, URLResponse?, NetworkingError?) -> Void) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return completion(nil, nil, nil) }

        let multipart = MultipartFormDataBuilder()

        filesToUpload.forEach { file in
            multipart.addFile(
                fieldName: file.fieldName.rawValue,
                fileName: file.fileName,
                mimeType: file.mimeType,
                fileData: file.data
            )
        }

        let body = multipart.build()

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue

        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }

        urlRequest.httpBody = body
        urlRequest.setValue(multipart.contentTypeHeader, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        urlRequest.setValue("Bearer \(bearerToken(for: auth))", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")

        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(ipAddress, forHTTPHeaderField: "ip_address")
        }

        urlSession.dataTask(with: urlRequest) { data, response, error in
            var networkingError: NetworkingError?

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                networkingError = NetworkingError.serverError(statusCode: httpResponse.statusCode, errorDescription: error?.localizedDescription ?? "")
            } else if data == nil {
                networkingError = NetworkingError.noData
            } else if let urlError = error as? URLError {
                switch urlError {
                case URLError.cannotFindHost:
                    networkingError = NetworkingError.invalidURL
                case URLError.cannotDecodeRawData:
                    networkingError = NetworkingError.decodingFailed
                default:
                    networkingError = NetworkingError.unknownError
                }
            }

            completion(data, response, networkingError)
        }.resume()
    }

    func configureEvervault() {
        Task {
            if let configResponse = try? await ConfigurationAPI.getEvervaultConfiguration() {
                Evervault.shared.configure(teamId: configResponse.teamId ?? "", appId: configResponse.appId ?? "")
                FrameNetworking.shared.isEvervaultConfigured = true
            } else if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.evervault.rawValue) {
                if let response = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetEvervaultConfigurationResponse.self, from: data) {
                    Evervault.shared.configure(teamId: response.teamId ?? "", appId: response.appId ?? "")
                    FrameNetworking.shared.isEvervaultConfigured = true
                }
            }
        }
    }

    private func printDataForTesting(data: Data?) {
        print(returnErrorString(data: data))
    }

    private func returnErrorString(data: Data?) -> String {
        if let data, let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }

        return ""
    }
}

final class MultipartFormDataBuilder {

    private let boundary: String
    private var body = Data()

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    var contentTypeHeader: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    func addFile(
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
    }

    func build() -> Data {
        var finalBody = body
        finalBody.append("--\(boundary)--\r\n")
        return finalBody
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
