//
//  ProveAuthService.swift
//  Frame-iOS
//
//  Service that runs Prove mobile auth with token from createVerification and calls confirmVerification on success.
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

/// Closure invoked when Prove auth completes. Performs confirmVerification with accountId and verificationId from create.
public typealias ProveConfirmHandler = @Sendable (String, String) async throws -> Void

public final class ProveAuthService: @unchecked Sendable {
    private let accountId: String
    private let verificationId: String
    private let confirmHandler: ProveConfirmHandler
    private let otpProvider: ProveOtpProvider?
    
    private var proveAuth: ProveAuth?
    private var authFinishStep: AuthFinishStep?
    private var otpStartStep: ProveOtpStartStep?
    private var otpFinishStep: ProveOtpFinishStep?

    public init(accountId: String, verificationId: String, confirmHandler: @escaping ProveConfirmHandler, otpProvider: ProveOtpProvider? = nil) {
        self.accountId = accountId
        self.verificationId = verificationId
        self.confirmHandler = confirmHandler
        self.otpProvider = otpProvider
    }

    /// Runs Prove mobile flow with auth token from createVerification. Returns true on success after confirmVerification succeeds.
    public func authenticateWith(authToken: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let once = ProveOneTimeResume(continuation: continuation)
            authFinishStep = AuthFinishStep(accountId: accountId, verificationId: verificationId, confirmHandler: confirmHandler) { [weak self] result in
                self?.releaseRetainedSDKObjects()
                once.resume(with: result)
            }
            otpStartStep = ProveOtpStartStep()
            otpFinishStep = ProveOtpFinishStep(otpProvider: otpProvider)

            guard let authFinishStep, let otpStartStep, let otpFinishStep else { return }
            proveAuth = ProveAuth.builder(authFinish: authFinishStep)
                .withOtpFallback(otpStart: otpStartStep, otpFinish: otpFinishStep)
                .build()

            DispatchQueue.global(qos: .userInitiated).async {
                guard let proveAuth = self.proveAuth else { return }
                proveAuth.authenticate(authToken: authToken) { error in
                    if error.errorDescription != nil {
                        self.releaseRetainedSDKObjects()
                        once.resume(with: .failure(error))
                    }
                }
            }
        }
    }

    private func releaseRetainedSDKObjects() {
        proveAuth = nil
        authFinishStep = nil
        otpStartStep = nil
        otpFinishStep = nil
    }
}

// MARK: - One-time resume (avoid double-resume from step vs completion)

private final class ProveOneTimeResume: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Bool, Error>?

    init(continuation: CheckedContinuation<Bool, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<Bool, Error>) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        cont?.resume(with: result)
    }
}

// MARK: - AuthFinishStep

private final class AuthFinishStep: NSObject, ProveAuthFinishStep, @unchecked Sendable {
    private let accountId: String
    private let verificationId: String
    private let confirmHandler: ProveConfirmHandler
    private let onResult: @Sendable (Result<Bool, Error>) -> Void

    init(accountId: String, verificationId: String, confirmHandler: @escaping ProveConfirmHandler, onResult: @escaping @Sendable (Result<Bool, Error>) -> Void) {
        self.accountId = accountId
        self.verificationId = verificationId
        self.confirmHandler = confirmHandler
        self.onResult = onResult
    }

    func execute(authId: String) {
        Task {
            do {
                try await confirmHandler(accountId, verificationId)
                onResult(.success(true))
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
