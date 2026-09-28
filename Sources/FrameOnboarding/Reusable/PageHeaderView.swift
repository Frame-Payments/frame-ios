//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/11/25.
//

import SwiftUI
import Frame

struct PageHeaderView: View {
    @Environment(\.frameTheme) private var theme

    var useCloseButton: Bool = false
    /// When `false`, the chevron/close control is omitted — used on the first step when there is no intro to return to.
    var showsBackButton: Bool = true

    let headerTitle: String
    let buttonAction: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: showsBackButton ? 4 : 0) {
            if showsBackButton {
                Button {
                    buttonAction()
                } label: {
                    Image(useCloseButton ? "close-icon-white" : "left-chevron", bundle: FrameResources.module)
                        .foregroundStyle(theme.colors.textPrimary)
                }
                .frame(width: 44.0, height: 44.0)
            }

            Text(headerTitle)
                .font(theme.fonts.heading)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20.0)
        }
        .padding(.top, showsBackButton ? theme.spacing.sectionGap : theme.spacing.sectionTop)
    }
}

#Preview("Dark") {
    PageHeaderView(headerTitle: "Example Title", buttonAction: {})
        .preferredColorScheme(.dark)
}

#Preview {
    PageHeaderView(headerTitle: "Example Title", buttonAction: {})
}

#Preview("No back") {
    PageHeaderView(showsBackButton: false, headerTitle: "Verify your phone number with a code", buttonAction: {})
}
