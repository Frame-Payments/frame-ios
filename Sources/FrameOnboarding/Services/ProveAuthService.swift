//
//  ProveAuthService.swift
//  Frame-iOS
//
//  Standalone service that runs Prove mobile auth (phone + DOB) and returns user info.
//  Runs ProveAuth.authenticate() off the main thread; uses backend for token and verify.
//

import Foundation
import ProveAuth

/// Optional async closure the host provides to supply OTP when the SDK falls back to OTP. Return nil to cancel.
public typealias ProveOtpProvider = @Sendable () async -> String?

/// User information returned after successful Prove authentication and backend verify.
public struct ProveUserInfo: Sendable {
    public let firstName: String
    public let lastName: String

    public init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}

/// Backend that provides Prove auth token and verify. Implement with your backend (e.g. Frame proxy or app server).
public protocol ProveAuthBackend: Sendable {
    /// Obtain an auth token for the Prove SDK (e.g. from your backend's Prove Start with phone, DOB, flow type).
    func getAuthToken(phoneNumber: String, dateOfBirth: String, flowType: String) async throws -> String

    /// Verify the auth session and return user info (e.g. from your backend's Prove Validate/Challenge).
    func verify(authId: String) async throws -> ProveUserInfo
}


public final class ProveAuthService: @unchecked Sendable {
    private let backend: ProveAuthBackend
    private let otpProvider: ProveOtpProvider?

    public init(backend: ProveAuthBackend, otpProvider: ProveOtpProvider? = nil) {
        self.backend = backend
        self.otpProvider = otpProvider
    }

    /// Runs Prove mobile flow with phone and DOB; returns user info on success. Call from main or background.
    public func authenticate(phoneNumber: String, dateOfBirth: String) async throws -> ProveUserInfo {
        let authToken = try await backend.getAuthToken(phoneNumber: phoneNumber, dateOfBirth: dateOfBirth, flowType: "mobile")

        return try await withCheckedThrowingContinuation { continuation in
            let once = ProveOneTimeResume(continuation: continuation)
            let finishStep = AuthFinishStep(backend: backend) { result in
                once.resume(with: result)
            }
            let otpStart = ProveOtpStartStep()
            let otpFinish = ProveOtpFinishStep(otpProvider: otpProvider)

            let proveAuth = ProveAuth.builder(authFinish: finishStep)
                .withOtpFallback(otpStart: otpStart, otpFinish: otpFinish)
                .build()

            DispatchQueue.global(qos: .userInitiated).async {
                proveAuth.authenticate(authToken: authToken) { error in
                    if error.errorDescription != nil {
                        once.resume(with: .failure(error))
                    }
                }
            }
        }
    }
}

// MARK: - One-time resume (avoid double-resume from step vs completion)

private final class ProveOneTimeResume: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<ProveUserInfo, Error>?

    init(continuation: CheckedContinuation<ProveUserInfo, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<ProveUserInfo, Error>) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        cont?.resume(with: result)
    }
}

// MARK: - AuthFinishStep

private final class AuthFinishStep: NSObject, ProveAuthFinishStep, @unchecked Sendable {
    private let backend: ProveAuthBackend
    private let onResult: @Sendable (Result<ProveUserInfo, Error>) -> Void

    init(backend: ProveAuthBackend, onResult: @escaping @Sendable (Result<ProveUserInfo, Error>) -> Void) {
        self.backend = backend
        self.onResult = onResult
    }

    func execute(authId: String) {
        Task {
            do {
                let info = try await backend.verify(authId: authId)
                onResult(.success(info))
            } catch {
                onResult(.failure(error))
            }
        }
    }
}

// MARK: - OtpStartStep (phone already provided at Start)

private final class ProveOtpStartStep: NSObject, OtpStartStep, @unchecked Sendable {
    func execute(phoneNumberNeeded: Bool, phoneValidationError: ProveAuthError?, callback: any OtpStartStepCallback) {
        if phoneNumberNeeded {
            callback.onError()
        } else {
            callback.onSuccess(input: nil)
        }
    }
}

// MARK: - OtpFinishStep (collect OTP via provider)

private final class ProveOtpFinishStep: NSObject, OtpFinishStep, @unchecked Sendable {
    private let otpProvider: ProveOtpProvider?

    init(otpProvider: ProveOtpProvider?) {
        self.otpProvider = otpProvider
    }

    func execute(otpError: ProveAuthError?, callback: any OtpFinishStepCallback) {
        guard let otpProvider = otpProvider else {
            callback.onError()
            return
        }
        Task { @MainActor in
            let otp = await otpProvider()
            if let otp = otp {
                callback.onSuccess(input: OtpFinishInput(otp: otp))
            } else {
                callback.onError()
            }
        }
    }
}

/// Errors that can occur during Prove authentication.
public enum ProveAuthServiceError: Error, LocalizedError, Sendable {
    /// Backend failed to return an auth token (e.g. network or invalid response).
    case authTokenFailed(underlying: Error)
    /// Backend verify failed (e.g. validation failed or network error).
    case verifyFailed(underlying: Error)
    /// User cancelled or OTP provider returned nil.
    case cancelled
    /// Prove SDK reported an error.
    case sdkError(underlying: Error)
    /// Unknown or unexpected error.
    case unknown(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .authTokenFailed(let underlying):
            return "Failed to get auth token: \(underlying.localizedDescription)"
        case .verifyFailed(let underlying):
            return "Verification failed: \(underlying.localizedDescription)"
        case .cancelled:
            return "Authentication was cancelled."
        case .sdkError(let underlying):
            return "Prove SDK error: \(underlying.localizedDescription)"
        case .unknown(let underlying):
            return underlying.localizedDescription
        }
    }
}
