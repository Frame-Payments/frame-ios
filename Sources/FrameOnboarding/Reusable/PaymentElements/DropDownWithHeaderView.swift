//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

public struct DropDownWithHeaderView: View {
    @Environment(\.frameTheme) private var theme

    @Binding public var headerText: String
    @Binding public var dropDownText: String
    @Binding public var showDropdownPicker: Bool

    @State public var showHeaderText: Bool = true
    @State public var showDropdownBorder: Bool = true

    public var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text(headerText)
                    .bold()
                    .font(theme.fonts.label)
                    .padding([.horizontal, .top])
            }
            HStack {
                Text(dropDownText)
                    .fontWeight(.medium)
                    .font(theme.fonts.label)
                    .padding(showDropdownBorder ? .all : .vertical)
                Spacer()
                Image("down-chevron", bundle: FrameResources.module)
                    .padding()
            }
            .frame(maxWidth: .infinity, minHeight: 42.0)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .stroke(theme.colors.surfaceStroke, lineWidth: showDropdownBorder ? 1 : 0)
            )
            .padding([.horizontal])
            .onTapGesture {
                self.showDropdownPicker.toggle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 40.0) {
        DropDownWithHeaderView(headerText: .constant("Example Title"),
                               dropDownText: .constant("Example Text"),
                               showDropdownPicker: .constant(false))
        DropDownWithHeaderView(headerText: .constant("Example Title"),
                               dropDownText: .constant("Example Text"),
                               showDropdownPicker: .constant(false),
                               showHeaderText: false)
        DropDownWithHeaderView(headerText: .constant("Example Title"),
                               dropDownText: .constant("Example Text"),
                               showDropdownPicker: .constant(false),
                               showHeaderText: true, showDropdownBorder: false)
        DropDownWithHeaderView(headerText: .constant("Example Title"),
                               dropDownText: .constant("Example Text"),
                               showDropdownPicker: .constant(false),
                               showHeaderText: false, showDropdownBorder: false)
    }
}

#Preview("Dark") {
    DropDownWithHeaderView(headerText: .constant("Example Title"),
                           dropDownText: .constant("Example Text"),
                           showDropdownPicker: .constant(false))
        .preferredColorScheme(.dark)
}
