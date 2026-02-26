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
