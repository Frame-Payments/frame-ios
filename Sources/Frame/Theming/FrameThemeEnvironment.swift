//
//  FrameThemeEnvironment.swift
//  Frame-iOS
//
//  SwiftUI environment plumbing for FrameTheme. Consumers either call
//  `.frameTheme(_:)` to scope a theme to a subtree, or set an SDK-wide
//  default once via `FrameNetworking.shared.configureTheme(_:)`. Every
//  Frame UI component reads the value via `@Environment(\.frameTheme)`.
//

import SwiftUI

private struct FrameThemeKey: EnvironmentKey {
    // SwiftUI evaluates EnvironmentKey.defaultValue on the main thread
    // during body recompute, so assuming MainActor isolation here lets us
    // reach the @MainActor-isolated FrameNetworking.shared.globalTheme
    // without forcing EnvironmentKey itself to become @MainActor.
    static var defaultValue: FrameTheme {
        MainActor.assumeIsolated { FrameNetworking.shared.globalTheme }
    }
}

public extension EnvironmentValues {
    /// The active ``FrameTheme`` for the current SwiftUI subtree.
    ///
    /// Frame UI components read this value automatically. Set it via
    /// ``View/frameTheme(_:)`` to scope a custom theme to a subtree, or
    /// configure an SDK-wide default through
    /// `FrameNetworking.shared.configureTheme(_:)`.
    var frameTheme: FrameTheme {
        get { self[FrameThemeKey.self] }
        set { self[FrameThemeKey.self] = newValue }
    }
}

public extension View {
    /// Applies a ``FrameTheme`` to this view and all Frame UI components in its subtree.
    ///
    /// - Parameter theme: The theme to inject into the SwiftUI environment.
    /// - Returns: A view whose ``EnvironmentValues/frameTheme`` is set to `theme`.
    func frameTheme(_ theme: FrameTheme) -> some View {
        environment(\.frameTheme, theme)
    }
}
