//
//  TransferV2ClientSecret.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

/// Errors raised while confirming a V2 transfer from the app.
public enum FrameTransferV2Error: Error, Equatable {
    /// Confirm was asked to run without a transfer id.
    case missingTransfer
    /// The transfer requires 3D Secure but carried no challenge session to present.
    case missingThreeDSecureChallenge
    /// The challenge never ran.
    case threeDSecureUnavailable(underlying: Error?)
    /// The status could not be read after every attempt.
    case statusUnavailable(attempts: Int, underlying: Error?)

    public static func == (lhs: FrameTransferV2Error, rhs: FrameTransferV2Error) -> Bool {
        switch (lhs, rhs) {
        case (.missingTransfer, .missingTransfer),
             (.missingThreeDSecureChallenge, .missingThreeDSecureChallenge),
             (.threeDSecureUnavailable, .threeDSecureUnavailable):
            return true
        case (.statusUnavailable(let l, _), .statusUnavailable(let r, _)):
            return l == r
        default:
            return false
        }
    }
}

/// The result of confirming a V2 transfer from the app.
public enum FrameTransferV2Outcome: Sendable, Equatable {
    /// Payment succeeded or is authorized awaiting capture.
    case succeeded(FrameObjects.TransferV2)
    /// Terminal payment failure.
    case failed(FrameObjects.TransferV2, message: String?)
    /// Polling exhausted before a terminal payment status.
    case timedOut

    static func terminalOutcome(for transfer: FrameObjects.TransferV2) -> FrameTransferV2Outcome? {
        let paymentStatus = transfer.payment?.status
        switch paymentStatus {
        case "succeeded", "requires_capture":
            return .succeeded(transfer)
        case "failed", "canceled":
            return .failed(transfer, message: transfer.payment?.failureReason)
        default:
            break
        }
        switch transfer.status {
        case .completed:
            return .succeeded(transfer)
        case .failed, .canceled:
            return .failed(transfer, message: transfer.payment?.failureReason)
        default:
            return nil
        }
    }
}
