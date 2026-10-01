//
//  TransferV2ClientSecret.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

/// A V2 transfer's `client_secret`, split into the pieces the API expects separately.
///
/// Accepts `tr_<id>_secret_<token>` (preferred) and `ci_<id>_secret_<token>` during the
/// bridge while V2 payments may still mint ChargeIntent-shaped secrets.
public struct TransferV2ClientSecret: Sendable, Equatable {
    /// The secret exactly as issued.
    public let value: String
    /// The bare transfer resource id for the URL path.
    public let transferID: String

    /// Parses a V2 transfer (or bridge ChargeIntent-shaped) client secret.
    public init(_ value: String) throws {
        if value.hasPrefix("tr_") {
            self.value = value
            self.transferID = try Self.parseID(value, prefix: "tr_")
            return
        }
        if value.hasPrefix("ci_") {
            // Bridge: some V2 flows may still hand a ChargeIntent secret to the client.
            self.value = value
            self.transferID = try Self.parseID(value, prefix: "ci_")
            return
        }
        throw FrameTransferV2Error.invalidClientSecret
    }

    private static func parseID(_ value: String, prefix: String) throws -> String {
        let withoutSecret: String
        if let marker = value.range(of: "_secret_"), marker.lowerBound > value.startIndex {
            withoutSecret = String(value[value.startIndex..<marker.lowerBound])
        } else {
            withoutSecret = value
        }
        let id = String(withoutSecret.dropFirst(prefix.count))
        guard !id.isEmpty else { throw FrameTransferV2Error.invalidClientSecret }
        return id
    }
}

/// Errors raised while confirming a V2 transfer from the app.
public enum FrameTransferV2Error: Error, Equatable {
    /// The string is not a recognised transfer `client_secret`.
    case invalidClientSecret
    /// The transfer requires 3D Secure but carried no challenge session to present.
    case missingThreeDSecureChallenge
    /// The challenge never ran.
    case threeDSecureUnavailable(underlying: Error?)
    /// The status could not be read after every attempt.
    case statusUnavailable(attempts: Int, underlying: Error?)

    public static func == (lhs: FrameTransferV2Error, rhs: FrameTransferV2Error) -> Bool {
        switch (lhs, rhs) {
        case (.invalidClientSecret, .invalidClientSecret),
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
