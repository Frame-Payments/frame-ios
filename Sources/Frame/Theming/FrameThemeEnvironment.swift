//
//  FrameThemeEnvironment.swift
//  Frame-iOS
//
//  SwiftUI environment plumbing for FrameTheme. Consumers call
//  `.frameTheme(_:)` once at their SDK entry point; every Frame UI
//  component reads the value via `@Environment(\.frameTheme)`.
//

import SwiftUI

private struct FrameThemeKey: EnvironmentKey {
    static let defaultValue = FrameTheme.default
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
