//
//  ProveAuthServiceError.swift
//  Frame-iOS
//
//  Typed errors for ProveAuthService for use by the UI layer.
//

import Foundation

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
