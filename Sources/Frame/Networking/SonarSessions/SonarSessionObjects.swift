//
//  File.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 3/2/26.
//

import Foundation

public protocol SessionStorage {
    func get() -> SessionId?
    func set(_ value: SessionId)
    func clear()
}

public final class UserDefaultsSessionStorage: SessionStorage {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "frame_charge_session_id") {
        self.defaults = defaults
        self.key = key
    }

    public func get() -> SessionId? {
        defaults.string(forKey: key)
    }

    public func set(_ value: SessionId) {
        defaults.set(value, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}

public class SonarSessionStorage {
    public static func currentSessionId() -> SessionId? {
        UserDefaults.standard.string(forKey: "frame_charge_session_id")
    }
}
