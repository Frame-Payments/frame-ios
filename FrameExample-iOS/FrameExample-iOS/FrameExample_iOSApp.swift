//
//  FrameExample_iOSApp.swift
//  FrameExample-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import SwiftUI
import Frame

@main
struct FrameExample_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Uncomment to apply a custom theme to every Frame SDK component:
                // .frameTheme(FrameTheme(
                //     colors: .init(primaryButton: .purple, error: .orange),
                //     fonts: .init(title: .custom("Avenir-Black", size: 28)),
                //     radii: .init(medium: 16)
                // ))
        }
    }
}
