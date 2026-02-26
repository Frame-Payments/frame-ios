//
//  ProveAuthBackend.swift
//  Frame-iOS
//
//  Backend-agnostic contract for Prove Auth: token retrieval and verify.
//  Implement this protocol to supply authToken (e.g. from your backend's Prove Start)
//  and to verify authId and return user info (e.g. from your backend's Prove Validate).
//

import Foundation

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
