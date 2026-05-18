//
//  FrameTheme.swift
//  Frame-iOS
//
//  SDK-wide theming primitives. Inject via `.frameTheme(_:)` at the SDK boundary
//  to override colors, fonts, and corner radii across cart, checkout, onboarding,
//  and every reusable component.
//

import SwiftUI

public struct FrameTheme: Equatable {
    public var colors: Colors
    public var fonts: Fonts
    public var radii: Radii

    public init(colors: Colors = .init(), fonts: Fonts = .init(), radii: Radii = .init()) {
        self.colors = colors
        self.fonts = fonts
        self.radii = radii
    }

    public static let `default` = FrameTheme()

    /// Returns a copy of `self` with the supplied transform applied.
    /// Use for terse one-off tweaks: `FrameTheme.default.with { $0.colors.primaryButton = .purple }`.
    public func with(_ transform: (inout FrameTheme) -> Void) -> FrameTheme {
        var copy = self
        transform(&copy)
        return copy
    }

    public struct Colors: Equatable {
        public var primaryButton: Color
        public var primaryButtonText: Color
        public var secondaryButton: Color
        public var secondaryButtonText: Color
        public var disabledButton: Color
        public var disabledButtonStroke: Color
        public var disabledButtonText: Color
        public var surface: Color
        public var surfaceStroke: Color
        public var textPrimary: Color
        public var textSecondary: Color
        public var error: Color
        public var toastBackground: Color
        public var toastText: Color
        public var onboardingHeaderBackground: Color
        public var onboardingProgressFilledOnBrand: Color
        public var onboardingProgressEmptyOnBrand: Color

        public init(
            primaryButton: Color = Color("MainButtonColor", bundle: FrameResources.module),
            primaryButtonText: Color = .white,
            secondaryButton: Color = Color(.systemBackground),
            secondaryButtonText: Color = Color("MainButtonColor", bundle: FrameResources.module),
            disabledButton: Color = Color("UnfilledButtonColor", bundle: FrameResources.module),
            disabledButtonStroke: Color = Color("UnfilledButtonStrokeColor", bundle: FrameResources.module),
            disabledButtonText: Color = Color("UnfilledButtonTextColor", bundle: FrameResources.module),
            surface: Color = Color("SurfaceColor", bundle: FrameResources.module),
            surfaceStroke: Color = Color("SurfaceStrokeColor", bundle: FrameResources.module),
            textPrimary: Color = Color("PrimaryTextColor", bundle: FrameResources.module),
            textSecondary: Color = Color("TextColorSecondary", bundle: FrameResources.module),
            error: Color = .red,
            toastBackground: Color = .red,
            toastText: Color = .white,
            onboardingHeaderBackground: Color = Color("OnboardingHeaderBackground", bundle: FrameResources.module),
            onboardingProgressFilledOnBrand: Color = .white,
            onboardingProgressEmptyOnBrand: Color = .white.opacity(0.25)
        ) {
            self.primaryButton = primaryButton
            self.primaryButtonText = primaryButtonText
            self.secondaryButton = secondaryButton
            self.secondaryButtonText = secondaryButtonText
            self.disabledButton = disabledButton
            self.disabledButtonStroke = disabledButtonStroke
            self.disabledButtonText = disabledButtonText
            self.surface = surface
            self.surfaceStroke = surfaceStroke
            self.textPrimary = textPrimary
            self.textSecondary = textSecondary
            self.error = error
            self.toastBackground = toastBackground
            self.toastText = toastText
            self.onboardingHeaderBackground = onboardingHeaderBackground
            self.onboardingProgressFilledOnBrand = onboardingProgressFilledOnBrand
            self.onboardingProgressEmptyOnBrand = onboardingProgressEmptyOnBrand
        }
    }

    public struct Fonts: Equatable {
        public var title: Font
        public var heading: Font
        public var headline: Font
        public var body: Font
        public var bodySmall: Font
        public var label: Font
        public var caption: Font
        public var button: Font

        public init(
            title: Font = .title,
            heading: Font = .system(size: 18, weight: .semibold),
            headline: Font = .headline,
            body: Font = .body,
            bodySmall: Font = .system(size: 14),
            label: Font = .subheadline,
            caption: Font = .caption,
            button: Font = .headline
        ) {
            self.title = title
            self.heading = heading
            self.headline = headline
            self.body = body
            self.bodySmall = bodySmall
            self.label = label
            self.caption = caption
            self.button = button
        }
    }

    public struct Radii: Equatable {
        public var small: CGFloat
        public var medium: CGFloat
        public var large: CGFloat

        public init(small: CGFloat = 8, medium: CGFloat = 10, large: CGFloat = 16) {
            self.small = small
            self.medium = medium
            self.large = large
        }
    }
}
