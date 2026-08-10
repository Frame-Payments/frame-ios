//
//  SonarSessionRefreshModifier.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/10/26.
//

import SwiftUI

// MARK: - View + Sonar session refresh

/// Hooks Sonar session upkeep to the presentation of the SDK's entry-point views.
public extension View {
    /// Records a Sonar device event when this view is presented.
    ///
    /// Apply to the SDK's entry-point views — onboarding, checkout, and the standalone payment
    /// elements. The web SDK writes the session once per page load; a native app has no page loads,
    /// so presenting one of these views is the equivalent moment, and the point at which the user has
    /// committed to a flow that risk checks will score.
    ///
    /// Runs in a detached task, so presentation is never blocked and a failure is silent — the payment
    /// path still calls `ensureSession(accountId:)` before charging.
    ///
    /// - Parameter accountId: The Frame account the flow belongs to, when known. Pass `nil` before an
    ///   account exists so the event lands on the pre-account session that later gets adopted.
    /// - Returns: A view that refreshes the Sonar session on appearance.
    func refreshesSonarSession(accountId: String? = nil) -> some View {
        task {
            await SessionManager.shared.refreshOnFlowEntry(accountId: accountId)
        }
    }
}
