//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

/// A backing store for the Sonar session identifiers held by the Frame SDK.
///
/// Sessions are scoped to a Frame account. `accountId: nil` addresses the pre-account slot, holding
/// a session minted before the account was known so it can be adopted once it is.
public protocol SessionStorage {
    /// Returns the session persisted for the given account, or `nil` if none is stored.
    func get(accountId: String?) -> SessionId?

    /// Persists a session identifier for the given account.
    ///
    /// - Parameters:
    ///   - value: The ``SessionId`` to store.
    ///   - accountId: The account the session belongs to, or `nil` for the pre-account slot.
    func set(_ value: SessionId, accountId: String?)

    /// Removes the persisted session identifier for the given account.
    func clear(accountId: String?)

    /// When the given account's session was last created or refreshed on the server, or `nil` when
    /// unknown.
    func lastRefresh(accountId: String?) -> Date?

    /// Records that the given account's session was created or refreshed on the server at `date`.
    func setLastRefresh(_ date: Date, accountId: String?)
}

/// A ``SessionStorage`` implementation backed by `UserDefaults`.
///
/// Keying per account is what stops one account's session being reused by the next account on the
/// same device.
public final class UserDefaultsSessionStorage: SessionStorage {
    /// The unscoped key predating per-account scoping. Still read so a session survives an SDK
    /// upgrade, but never written for an account-scoped session.
    static let legacyKey = "frame_charge_session_id"

    private static let keyPrefix = "frame_sonar_session_id_"
    private static let refreshSuffix = "_refreshed_at"

    private let defaults: UserDefaults

    /// Creates a new `UserDefaultsSessionStorage` instance.
    ///
    /// - Parameter defaults: The `UserDefaults` suite to use for persistence. Defaults to `.standard`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(for accountId: String?) -> String {
        guard let accountId, !accountId.isEmpty else { return Self.legacyKey }
        return Self.keyPrefix + accountId
    }

    /// Returns the session identifier stored for the given account, or `nil` if absent.
    public func get(accountId: String?) -> SessionId? {
        defaults.string(forKey: key(for: accountId))
    }

    /// Stores the given session identifier for the given account.
    public func set(_ value: SessionId, accountId: String?) {
        defaults.set(value, forKey: key(for: accountId))
    }

    /// Removes the session identifier for the given account.
    public func clear(accountId: String?) {
        let key = key(for: accountId)
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: key + Self.refreshSuffix)
    }

    /// Returns when the given account's session was last created or refreshed on the server,
    /// or `nil` if that is unknown.
    public func lastRefresh(accountId: String?) -> Date? {
        defaults.object(forKey: key(for: accountId) + Self.refreshSuffix) as? Date
    }

    /// Records that the given account's session was created or refreshed on the server at `date`.
    public func setLastRefresh(_ date: Date, accountId: String?) {
        defaults.set(date, forKey: key(for: accountId) + Self.refreshSuffix)
    }
}

/// A convenience class for reading the active Sonar charge session identifier from `UserDefaults`.
public class SonarSessionStorage {
    /// Returns the Sonar session identifier stored for `accountId`, or `nil` if none has been
    /// persisted. Pass `nil` to read the legacy, pre-account session.
    public static func currentSessionId(accountId: String? = nil) -> SessionId? {
        UserDefaultsSessionStorage().get(accountId: accountId)
    }
}
