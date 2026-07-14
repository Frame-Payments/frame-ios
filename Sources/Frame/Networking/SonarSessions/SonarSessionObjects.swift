//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

/// A protocol that defines read, write, and clear operations for persisting a ``SessionId``.
///
/// Sessions are scoped to a Frame account. Passing `accountId: nil` addresses the legacy,
/// pre-account slot, which exists so sessions minted before an account was known can be adopted
/// once the account is.
///
/// Conform to this protocol to provide a custom backing store for the active Sonar charge session
/// identifier used by the Frame SDK.
public protocol SessionStorage {
    /// Returns the session persisted for the given account, or `nil` if none is stored.
    func get(accountId: String?) -> SessionId?

    /// Persists a session identifier for the given account.
    ///
    /// - Parameters:
    ///   - value: The ``SessionId`` to store.
    ///   - accountId: The account the session belongs to, or `nil` for the legacy slot.
    func set(_ value: SessionId, accountId: String?)

    /// Removes the persisted session identifier for the given account.
    func clear(accountId: String?)

    /// The time the session for the given account was last created or refreshed on the server,
    /// or `nil` when unknown.
    func lastRefresh(accountId: String?) -> Date?

    /// Records that the session for the given account was refreshed on the server at `date`.
    func setLastRefresh(_ date: Date, accountId: String?)
}

/// A ``SessionStorage`` implementation backed by `UserDefaults`.
///
/// Sessions are keyed per account (`frame_sonar_session_id_{accountId}`) so that a session minted
/// for one account can never be reused by another on the same device. The unscoped legacy key is
/// retained for sessions created before an account is known; ``UserDefaultsSessionStorage`` only
/// reads it, and ``SessionManager`` clears it once the session has been adopted by an account.
public final class UserDefaultsSessionStorage: SessionStorage {
    /// The unscoped key used before per-account scoping existed. Still read so an in-flight session
    /// survives an SDK upgrade, but never written for an account-scoped session.
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
