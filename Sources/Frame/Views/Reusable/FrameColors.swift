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
}
