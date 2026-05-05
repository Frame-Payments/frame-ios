//
//  FrameColors.swift
//  Frame-iOS
//
//  Shared button/text colors. Lives in `Frame` so both Frame (checkout) and
//  FrameOnboarding can reference the same palette via the bundled colorset assets.
//

import SwiftUI

public struct FrameColors {
    // Reusable colors
    public static let secondaryTextColor = Color("TextColorSecondary", bundle: FrameResources.module)
    public static let mainButtonColor = Color("MainButtonColor", bundle: FrameResources.module)
    public static let unfilledButtonColor = Color("UnfilledButtonColor", bundle: FrameResources.module)
    public static let unfilledButtonStrokeColor = Color("UnfilledButtonStrokeColor", bundle: FrameResources.module)
    public static let unfilledButtonTextColor = Color("UnfilledButtonTextColor", bundle: FrameResources.module)

    // Semantic surface tokens — light/dark adaptive via asset catalog
    public static let surfaceColor = Color("SurfaceColor", bundle: FrameResources.module)
    public static let surfaceStrokeColor = Color("SurfaceStrokeColor", bundle: FrameResources.module)
    public static let primaryTextColor = Color("PrimaryTextColor", bundle: FrameResources.module)
    public static let onboardingHeaderBackground = Color("OnboardingHeaderBackground", bundle: FrameResources.module)

    // Camera tokens — intentionally non-adaptive (camera UX convention).
    public static let cameraOverlayColor = Color.black.opacity(0.8)
    public static let cameraStrokeColor = Color.white.opacity(0.95)

    // White-on-brand button text — intentionally non-adaptive.
    public static let brandButtonTextColor = Color.white

    // Onboarding progress indicator (dark-mode only — header background is brand navy in dark mode).
    public static let onboardingProgressFilledOnBrand = Color.white
    public static let onboardingProgressEmptyOnBrand = Color.white.opacity(0.25)
}
