//
//  MethodOptionRow.swift
//  Frame-iOS
//
//  FrameOS-style option row: icon + label + chevron in a thin bordered container.
//

import SwiftUI
import Frame

struct MethodOptionRow: View {
    @Environment(\.frameTheme) private var theme

    let iconName: String
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(iconName, bundle: FrameResources.module)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(title)
                    .font(theme.fonts.body)
                    .foregroundStyle(theme.colors.textPrimary)
                Spacer()
                Image("right-chevron", bundle: FrameResources.module)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .fill(theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .strokeBorder(theme.colors.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
