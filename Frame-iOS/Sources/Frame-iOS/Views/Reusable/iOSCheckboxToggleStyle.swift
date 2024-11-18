//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/15/24.
//

import SwiftUI

public struct iOSCheckboxToggleStyle: ToggleStyle {
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
