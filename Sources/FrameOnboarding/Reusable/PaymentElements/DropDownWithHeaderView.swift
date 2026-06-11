//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

/// A reusable SwiftUI view that pairs an optional bold header label with a tappable
/// dropdown selector row, used throughout the onboarding payment elements to let
/// users open a picker sheet for a given field.
public struct DropDownWithHeaderView: View {
    @Environment(\.frameTheme) private var theme

    /// The label displayed above the dropdown row.
    @Binding public var headerText: String
    /// The currently selected value shown inside the dropdown row.
    @Binding public var dropDownText: String
    /// Controls whether the associated picker sheet is visible; toggled when the row is tapped.
    @Binding public var showDropdownPicker: Bool

    /// When `true`, the bold header label is rendered above the dropdown row.
    @State public var showHeaderText: Bool = true
    /// When `true`, a rounded-rectangle stroke border is drawn around the dropdown row.
    @State public var showDropdownBorder: Bool = true

    /// The SwiftUI view hierarchy for the header label and tappable dropdown row.
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
