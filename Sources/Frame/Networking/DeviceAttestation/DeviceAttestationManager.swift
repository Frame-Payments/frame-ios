//
//  DeviceAttestationManager.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/14/26.
//

import Foundation
import DeviceCheck
import CryptoKit
import Security

public enum DeviceAttestationError: Error {
    case notSupported
    case keyGenerationFailed(Error)
    case challengeFailed(NetworkingError?)
    case attestationFailed(Error)
    case attestationRejected(NetworkingError?)
    case noAttestedKey
    case assertionFailed(Error)
}

public class DeviceAttestationManager: ObservableObject {

    nonisolated(unsafe) public static let shared = DeviceAttestationManager()

    private let service = DCAppAttestService.shared
    private let keychainKey = "com.framepayments.device-attest-key-id"
    private let pendingKeychainKey = "com.framepayments.device-attest-key-id-pending"

    // MARK: - Published state

    /// Whether the device has been successfully attested. Observed by FrameApplePayButton
    /// to hide itself when attestation has not completed or has failed.
    @Published public var isDeviceAttested: Bool = false

    // MARK: - Public API

    /// Whether this device supports App Attest.
    public var isSupported: Bool {
        service.isSupported
    }

    /// The attested key ID stored in the Keychain, or nil if the device has not been attested yet.
    public var attestedKeyId: String? {
        readKeyIdFromKeychain()
    }

    private init() {
        isDeviceAttested = readKeychainItem(keychainKey) != nil
    }

    /// Performs the full device attestation flow:
    /// 1. Generate a key in the Secure Enclave
    /// 2. Fetch a challenge from the Frame backend
    /// 3. Attest the key with Apple
    /// 4. Send the attestation to the Frame backend for verification
    /// 5. Persist the key ID in the Keychain
    ///
    /// If a key has already been attested, this method returns the existing key ID.
    public func attestDevice() async throws -> String {
        if let existingKeyId = attestedKeyId {
            return existingKeyId
        }

        guard isSupported else {
            throw DeviceAttestationError.notSupported
        }

        // 1. Generate a key in the Secure Enclave and persist immediately.
        //    If a later step fails, retries will reuse this key instead of
        //    orphaning keys in the Secure Enclave.
        let keyId: String
        do {
            keyId = try await service.generateKey()
            savePendingKeyIdToKeychain(keyId)
        } catch {
            throw DeviceAttestationError.keyGenerationFailed(error)
        }

        // 2. Fetch challenge from backend
        let (challengeResponse, challengeError) = try await DeviceAttestationAPI.getChallenge()
        guard let challenge = challengeResponse?.challenge else {
            throw DeviceAttestationError.challengeFailed(challengeError)
        }

        // 3. Hash the challenge and attest the key with Apple
        guard let challengeData = Data(base64Encoded: challenge) else {
            throw DeviceAttestationError.challengeFailed(nil)
        }
        let clientDataHash = Data(SHA256.hash(data: challengeData))

        let attestationObject: Data
        do {
            attestationObject = try await service.attestKey(keyId, clientDataHash: clientDataHash)
        } catch {
            // attestKey is single-use per key — if it fails, the key cannot be reused.
            deletePendingKeyIdFromKeychain()
            throw DeviceAttestationError.attestationFailed(error)
        }

        // 4. Send attestation to backend for verification
        let (attestResponse, attestError) = try await DeviceAttestationAPI.attest(
            keyId: keyId,
            attestationObject: attestationObject,
            challenge: challenge
        )
        guard attestResponse?.status == "verified" else {
            deletePendingKeyIdFromKeychain()
            throw DeviceAttestationError.attestationRejected(attestError)
        }

        // 5. Promote the pending key to attested
        promoteKeyId(keyId)
        await MainActor.run { isDeviceAttested = true }
        return keyId
    }

    /// Generates an assertion for a payment request.
    /// Returns (keyId, assertion, clientData) all base64-encoded and ready for the API request.
    public func generateAssertionForPayment(paymentData: Data) async throws -> (keyId: String, assertion: String, clientData: String) {
        guard let keyId = attestedKeyId else {
            throw DeviceAttestationError.noAttestedKey
        }

        let clientDataDict: [String: String] = [
            "challenge": paymentData.base64EncodedString(),
            "origin": "ios-sdk"
        ]
        let clientDataJSON = try JSONSerialization.data(withJSONObject: clientDataDict)
        let clientDataHash = Data(SHA256.hash(data: clientDataJSON))

        let assertionData: Data
        do {
            assertionData = try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
        } catch {
            throw DeviceAttestationError.assertionFailed(error)
        }

        return (
            keyId: keyId,
            assertion: assertionData.base64EncodedString(),
            clientData: clientDataJSON.base64EncodedString()
        )
    }

    /// Removes the stored key ID. Call this if the backend rejects the attestation
    /// and the device needs to be re-attested.
    public func resetAttestation() {
        deleteKeychainItem(keychainKey)
        deleteKeychainItem(pendingKeychainKey)
        isDeviceAttested = false
    }

    // MARK: - Keychain

    private func savePendingKeyIdToKeychain(_ keyId: String) {
        saveKeychainItem(pendingKeychainKey, value: keyId)
    }

    private func deletePendingKeyIdFromKeychain() {
        deleteKeychainItem(pendingKeychainKey)
    }

    /// Moves the key from pending to attested.
    private func promoteKeyId(_ keyId: String) {
        saveKeychainItem(keychainKey, value: keyId)
        deleteKeychainItem(pendingKeychainKey)
    }

    private func readKeyIdFromKeychain() -> String? {
        readKeychainItem(keychainKey)
    }

    private func saveKeychainItem(_ key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func readKeychainItem(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychainItem(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
