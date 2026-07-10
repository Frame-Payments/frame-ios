//
//  DeviceAttestationErrorTests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 7/10/26.
//

import XCTest
@testable import Frame

// MARK: - DeviceAttestationError.toastMessage() tests

final class DeviceAttestationErrorToastMessageTests: XCTestCase {

    /// A sample underlying system error standing in for a DeviceCheck/Secure Enclave failure.
    private let systemError = NSError(domain: "com.apple.devicecheck.error", code: 2)

    /// One instance of every case, used to assert cross-case properties.
    private var allCases: [DeviceAttestationError] {
        [
            .notSupported,
            .keyGenerationFailed(systemError),
            .challengeFailed(nil),
            .attestationFailed(systemError),
            .attestationRejected(nil),
            .noAttestedKey,
            .assertionFailed(systemError),
        ]
    }

    /// The regression this whole change exists to prevent: every case previously collapsed to one
    /// generic string, so a merchant bug report could not identify which step failed.
    func testEveryCaseProducesADistinctMessage() {
        let messages = allCases.map { $0.toastMessage() }
        XCTAssertEqual(Set(messages).count, allCases.count,
                       "Two or more DeviceAttestationError cases share a toast message")
    }

    func testAllMessagesArePrefixedForConsistencyWithNetworkingError() {
        for error in allCases {
            XCTAssertTrue(error.toastMessage().hasPrefix("Error: "),
                          "Missing 'Error: ' prefix: \(error.toastMessage())")
        }
    }

    /// The underlying system error is developer-facing and must never reach a payment screen.
    func testWrappedSystemErrorIsNeverLeakedIntoTheToast() {
        let wrapping: [DeviceAttestationError] = [
            .keyGenerationFailed(systemError),
            .attestationFailed(systemError),
            .assertionFailed(systemError),
        ]
        for error in wrapping {
            let message = error.toastMessage()
            XCTAssertFalse(message.contains("devicecheck"), "Leaked system error domain: \(message)")
            XCTAssertFalse(message.contains("Code=2"), "Leaked system error code: \(message)")
        }
    }

    // MARK: Server-supplied messages

    func testChallengeFailedPrefersServerEnvelopeMessage() {
        let networkingError = NetworkingError.serverError(
            statusCode: 422,
            errorDescription: #"{"error_details":{"message":"Challenge expired"}}"#
        )
        XCTAssertEqual(DeviceAttestationError.challengeFailed(networkingError).toastMessage(),
                       "Error: Challenge expired")
    }

    func testAttestationRejectedPrefersServerEnvelopeMessage() {
        let networkingError = NetworkingError.serverError(
            statusCode: 422,
            errorDescription: #"{"error_details":"Device not attested"}"#
        )
        XCTAssertEqual(DeviceAttestationError.attestationRejected(networkingError).toastMessage(),
                       "Error: Device not attested")
    }

    /// A nil NetworkingError, a non-server error, and an unparseable body all fall back to the
    /// static per-case text rather than surfacing an empty or garbled message.
    func testChallengeFailedFallsBackWhenNoServerMessageIsAvailable() {
        let fallback = DeviceAttestationError.challengeFailed(nil).toastMessage()
        XCTAssertEqual(DeviceAttestationError.challengeFailed(.unknownError).toastMessage(), fallback)
        XCTAssertEqual(
            DeviceAttestationError.challengeFailed(
                .serverError(statusCode: 500, errorDescription: "not json")
            ).toastMessage(),
            fallback
        )
        XCTAssertFalse(fallback.isEmpty)
    }
}

// MARK: - App Attest environment namespacing tests

final class AppAttestEnvironmentTests: XCTestCase {

    typealias Environment = DeviceAttestationManager.AppAttestEnvironment

    /// The regression that wedged the merchant: a development key reused by a TestFlight build.
    /// The two environments must never resolve to the same Keychain account.
    func testEnvironmentsProduceDistinctKeychainAccounts() {
        XCTAssertNotEqual(Environment.development.rawValue, Environment.production.rawValue)
    }

    /// Detection must be stable across calls — an unstable answer would re-attest on every launch,
    /// burning Secure Enclave keys and hammering the /attest endpoint.
    func testCurrentEnvironmentIsStableAcrossCalls() {
        let first = Environment.current
        for _ in 0..<10 {
            XCTAssertEqual(Environment.current, first)
        }
    }

    /// The test bundle carries no embedded.mobileprovision, so detection must report production
    /// rather than crashing or defaulting to development. This pins the fallback direction:
    /// mislabelling a dev build as production costs one re-attestation, which reset-and-retry
    /// absorbs; the reverse would let a dev key be trusted in production.
    func testAbsentProvisioningProfileResolvesToProduction() {
        XCTAssertNil(Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"))
        XCTAssertEqual(Environment.current, .production)
    }
}

// MARK: - DeviceAttestationError.debugDescription tests

final class DeviceAttestationErrorDebugDescriptionTests: XCTestCase {

    private let systemError = NSError(domain: "com.apple.devicecheck.error", code: 2)

    /// debugDescription is the escape hatch that recovers what the toast deliberately hides.
    func testDebugDescriptionIncludesTheWrappedSystemError() {
        let description = DeviceAttestationError.attestationFailed(systemError).debugDescription
        XCTAssertTrue(description.contains("attestationFailed"))
        XCTAssertTrue(description.contains("com.apple.devicecheck.error"))
    }

    func testDebugDescriptionNamesTheCaseForErrorsWithoutAPayload() {
        XCTAssertTrue(DeviceAttestationError.notSupported.debugDescription.contains("notSupported"))
        XCTAssertTrue(DeviceAttestationError.noAttestedKey.debugDescription.contains("noAttestedKey"))
    }

    func testDebugDescriptionHandlesAbsentNetworkingError() {
        let description = DeviceAttestationError.challengeFailed(nil).debugDescription
        XCTAssertTrue(description.contains("challengeFailed"))
        XCTAssertTrue(description.contains("no underlying NetworkingError"))
    }
}
