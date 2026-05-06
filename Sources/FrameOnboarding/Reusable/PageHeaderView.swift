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

    let headerTitle: String
    let buttonAction: () -> ()

    var body: some View {
        HStack(alignment: .center) {
            Button {
                buttonAction()
            } label: {
                Image(useCloseButton ? "close-icon-white" : "left-chevron", bundle: FrameResources.module)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .frame(width: 50.0, height: 50.0)

            Spacer()
            Text(headerTitle)
                .bold()
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Rectangle()
                .fill(.clear)
                .frame(width: 50.0, height: 50.0)
        }
    }
}

#Preview("Dark") {
    PageHeaderView(headerTitle: "Example Title", buttonAction: {})
        .preferredColorScheme(.dark)
}

#Preview {
    PageHeaderView(headerTitle: "Example Title", buttonAction: {})
}
