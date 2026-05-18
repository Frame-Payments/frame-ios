//
//  FrameToast.swift
//  Frame-iOS
//

import SwiftUI

/// Cross-target singleton that drives the transport-error toast. UI sites call
/// `FrameToastCenter.shared.show(...)` when a `NetworkingError.isTransport` failure occurs;
/// the modifier `frameToastOverlay()` (applied at the root of each SDK modal) renders the
/// current message at the bottom and auto-clears it after `autoDismissAfter` seconds.
///
/// Public so the `Frame-Onboarding` module can emit messages too; not intended as a generic
/// host-app toast API.
@MainActor
public final class FrameToastCenter: ObservableObject {
    public static let shared = FrameToastCenter()

    @Published public var current: String?

    private var dismissTask: Task<Void, Never>?

    public func show(_ message: String, autoDismissAfter seconds: Double = 4.0) {
        dismissTask?.cancel()
        current = message
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if !Task.isCancelled {
                self?.current = nil
            }
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}

private struct FrameToastView: View {
    @Environment(\.frameTheme) private var theme
    let message: String
    let onTap: () -> Void

    var body: some View {
        Text(message)
            .font(theme.fonts.bodySmall)
            .foregroundColor(theme.colors.toastText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .fill(theme.colors.toastBackground)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)
    }
}

private struct FrameToastOverlayModifier: ViewModifier {
    @ObservedObject private var center = FrameToastCenter.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let message = center.current {
                FrameToastView(message: message) { center.dismiss() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: center.current)
    }
}

extension View {
    /// Attaches the SDK transport-error toast overlay. Apply once at the root of a modal
    /// container (checkout / cart / onboarding).
    public func frameToastOverlay() -> some View {
        modifier(FrameToastOverlayModifier())
    }
}
