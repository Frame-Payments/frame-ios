//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

/// A protocol that defines read, write, and clear operations for persisting a ``SessionId``.
///
/// Conform to this protocol to provide a custom backing store for the active Sonar charge session
/// identifier used by the Frame SDK.
public protocol SessionStorage {
    /// Returns the currently persisted session identifier, or `nil` if none is stored.
    func get() -> SessionId?

    /// Persists the given session identifier to the backing store.
    ///
    /// - Parameter value: The ``SessionId`` to store.
    func set(_ value: SessionId)

    /// Removes the persisted session identifier from the backing store.
    func clear()
}

/// A ``SessionStorage`` implementation backed by `UserDefaults`.
///
/// This is the default session storage used by the Frame SDK to persist the active Sonar charge
/// session identifier across app launches.
public final class UserDefaultsSessionStorage: SessionStorage {
    private let defaults: UserDefaults
    private let key: String

    /// Creates a new `UserDefaultsSessionStorage` instance.
    ///
    /// - Parameters:
    ///   - defaults: The `UserDefaults` suite to use for persistence. Defaults to `.standard`.
    ///   - key: The key under which the session identifier is stored. Defaults to
    ///     `"frame_charge_session_id"`.
    public init(defaults: UserDefaults = .standard, key: String = "frame_charge_session_id") {
        self.defaults = defaults
        self.key = key
    }

    /// Returns the session identifier stored under the configured key, or `nil` if absent.
    public func get() -> SessionId? {
        defaults.string(forKey: key)
    }

    /// Stores the given session identifier under the configured key.
    ///
    /// - Parameter value: The ``SessionId`` to persist.
    public func set(_ value: SessionId) {
        defaults.set(value, forKey: key)
    }

    /// Removes the session identifier from `UserDefaults`.
    public func clear() {
        defaults.removeObject(forKey: key)
    }
}

/// A convenience class for reading the active Sonar charge session identifier from `UserDefaults`.
///
/// Use ``currentSessionId()`` to retrieve the session identifier that was last persisted by the
/// Frame SDK without needing a full ``SessionStorage`` instance.
public class SonarSessionStorage {
    /// Returns the active Sonar charge session identifier stored in `UserDefaults.standard`, or
    /// `nil` if no session has been persisted.
    public static func currentSessionId() -> SessionId? {
        UserDefaults.standard.string(forKey: "frame_charge_session_id")
    }
}
