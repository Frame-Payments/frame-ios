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
    var frameTheme: FrameTheme {
        get { self[FrameThemeKey.self] }
        set { self[FrameThemeKey.self] = newValue }
    }
}

public extension View {
    func frameTheme(_ theme: FrameTheme) -> some View {
        environment(\.frameTheme, theme)
    }
}
