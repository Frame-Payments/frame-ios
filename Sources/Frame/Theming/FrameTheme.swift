//
//  FrameTheme.swift
//  Frame-iOS
//
//  SDK-wide theming primitives. Inject via `.frameTheme(_:)` at the SDK boundary
//  to override colors, fonts, and corner radii across cart, checkout, onboarding,
//  and every reusable component.
//

import SwiftUI

/// The root theming value that controls the visual appearance of all Frame SDK UI.
///
/// Create a customised theme by starting from ``default`` and using ``with(_:)`` for
/// one-off tweaks, or by constructing a fully custom instance via ``init(colors:fonts:radii:)``.
/// Inject it at the SDK entry point using the `.frameTheme(_:)` view modifier.
public struct FrameTheme: Equatable {
    /// The color palette used across all SDK components.
    public var colors: Colors
    /// The font scale used across all SDK components.
    public var fonts: Fonts
    /// The corner-radius scale used across all SDK components.
    public var radii: Radii

    /// Creates a ``FrameTheme`` with the given sub-themes, falling back to SDK defaults for any omitted arguments.
    ///
    /// - Parameters:
    ///   - colors: The color palette to apply. Defaults to ``Colors/init()``.
    ///   - fonts: The font scale to apply. Defaults to ``Fonts/init()``.
    ///   - radii: The corner-radius scale to apply. Defaults to ``Radii/init()``.
    public init(colors: Colors = .init(), fonts: Fonts = .init(), radii: Radii = .init()) {
        self.colors = colors
        self.fonts = fonts
        self.radii = radii
    }

    /// The out-of-the-box Frame theme used when no custom theme is injected.
    public static let `default` = FrameTheme()

    /// Returns a copy of `self` with the supplied transform applied.
    /// Use for terse one-off tweaks: `FrameTheme.default.with { $0.colors.primaryButton = .purple }`.
    public func with(_ transform: (inout FrameTheme) -> Void) -> FrameTheme {
        var copy = self
        transform(&copy)
        return copy
    }

    /// The color palette that drives every Frame SDK component.
    ///
    /// All properties have SDK-provided defaults drawn from the bundle's asset catalogue,
    /// so you only need to override the values you want to change.
    public struct Colors: Equatable {
        /// Fill color for primary (CTA) buttons.
        public var primaryButton: Color
        /// Label color for primary (CTA) buttons.
        public var primaryButtonText: Color
        /// Fill color for secondary (outlined / ghost) buttons.
        public var secondaryButton: Color
        /// Label color for secondary (outlined / ghost) buttons.
        public var secondaryButtonText: Color
        /// Fill color for disabled buttons.
        public var disabledButton: Color
        /// Border color for disabled buttons.
        public var disabledButtonStroke: Color
        /// Label color for disabled buttons.
        public var disabledButtonText: Color
        /// Background color for cards, sheets, and input surfaces.
        public var surface: Color
        /// Border color for cards, sheets, and input surfaces.
        public var surfaceStroke: Color
        /// Default text color for headings and body copy.
        public var textPrimary: Color
        /// Subdued text color for captions and secondary labels.
        public var textSecondary: Color
        /// Color used for error states, validation messages, and destructive actions.
        public var error: Color
        /// Background color for in-app toast notifications.
        public var toastBackground: Color
        /// Text color for in-app toast notifications.
        public var toastText: Color
        /// Background color for the onboarding flow header bar.
        public var onboardingHeaderBackground: Color
        /// Color for the filled segment of the onboarding progress indicator, rendered on the brand header.
        public var onboardingProgressFilledOnBrand: Color
        /// Color for the empty segment of the onboarding progress indicator, rendered on the brand header.
        public var onboardingProgressEmptyOnBrand: Color

        /// Creates a ``Colors`` palette, falling back to SDK-bundled asset-catalogue colors for any omitted arguments.
        ///
        /// - Parameters:
        ///   - primaryButton: Fill color for primary buttons.
        ///   - primaryButtonText: Label color for primary buttons.
        ///   - secondaryButton: Fill color for secondary buttons.
        ///   - secondaryButtonText: Label color for secondary buttons.
        ///   - disabledButton: Fill color for disabled buttons.
        ///   - disabledButtonStroke: Border color for disabled buttons.
        ///   - disabledButtonText: Label color for disabled buttons.
        ///   - surface: Background color for cards and input surfaces.
        ///   - surfaceStroke: Border color for cards and input surfaces.
        ///   - textPrimary: Primary text color.
        ///   - textSecondary: Secondary / subdued text color.
        ///   - error: Color for error and destructive states.
        ///   - toastBackground: Background color for toast notifications.
        ///   - toastText: Text color for toast notifications.
        ///   - onboardingHeaderBackground: Background of the onboarding header bar.
        ///   - onboardingProgressFilledOnBrand: Filled progress segment color on the brand header.
        ///   - onboardingProgressEmptyOnBrand: Empty progress segment color on the brand header.
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

    /// The typographic scale used across all Frame SDK components.
    ///
    /// Override individual slots to substitute custom fonts while leaving the
    /// rest of the hierarchy intact.
    public struct Fonts: Equatable {
        /// Font used for large display titles (e.g. page headers).
        public var title: Font
        /// Font used for section headings within a page.
        public var heading: Font
        /// Font used for sub-section headlines and prominent labels.
        public var headline: Font
        /// Font used for standard body copy.
        public var body: Font
        /// Font used for smaller body copy and supplementary text.
        public var bodySmall: Font
        /// Font used for form field labels and list-item labels.
        public var label: Font
        /// Font used for captions and fine-print text.
        public var caption: Font
        /// Font used for button labels.
        public var button: Font

        /// Creates a ``Fonts`` scale, falling back to system-font equivalents for any omitted arguments.
        ///
        /// - Parameters:
        ///   - title: Font for large display titles.
        ///   - heading: Font for section headings.
        ///   - headline: Font for sub-section headlines.
        ///   - body: Font for standard body copy.
        ///   - bodySmall: Font for smaller body copy.
        ///   - label: Font for form-field and list-item labels.
        ///   - caption: Font for captions and fine-print text.
        ///   - button: Font for button labels.
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

    /// The corner-radius scale used to round UI surfaces and controls across the SDK.
    ///
    /// Apply these values consistently to buttons, cards, and input fields to maintain
    /// a cohesive visual style.
    public struct Radii: Equatable {
        /// Small corner radius, typically applied to tags, badges, and compact controls.
        public var small: CGFloat
        /// Medium corner radius, typically applied to buttons and input fields.
        public var medium: CGFloat
        /// Large corner radius, typically applied to cards, sheets, and modals.
        public var large: CGFloat

        /// Creates a ``Radii`` scale with the given values, falling back to SDK defaults for any omitted arguments.
        ///
        /// - Parameters:
        ///   - small: Radius for compact controls (default `8`).
        ///   - medium: Radius for buttons and inputs (default `10`).
        ///   - large: Radius for cards and sheets (default `16`).
        public init(small: CGFloat = 8, medium: CGFloat = 10, large: CGFloat = 16) {
            self.small = small
            self.medium = medium
            self.large = large
        }
    }
}
