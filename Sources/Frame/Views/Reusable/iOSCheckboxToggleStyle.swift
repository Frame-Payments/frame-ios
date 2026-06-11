//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/15/24.
//

import SwiftUI

/// A `ToggleStyle` that renders a SwiftUI `Toggle` as an iOS-style checkbox,
/// displaying a filled square when on and an empty square when off.
public struct iOSCheckboxToggleStyle: ToggleStyle {
    /// Creates the checkbox button view for the given toggle configuration.
    /// - Parameter configuration: The properties of the toggle, including its current state and label.
    /// - Returns: A `Button` styled as a checkbox with a system square icon and the toggle's label.
    public func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .tint(.gray)
                configuration.label
            }
        })
    }
}
