//
//  EncryptedPaymentCardInput.swift
//  Frame-iOS
//

import SwiftUI
import EvervaultInputs

/// A `PaymentCardInputStyle` that renders a themed, encrypted payment card input
/// composed of a card number field above a side-by-side expiry and CVC field,
/// styled according to the active ``FrameTheme``.
public struct EncryptedPaymentCardInput: PaymentCardInputStyle {
    /// Creates an ``EncryptedPaymentCardInput`` style instance.
    public init() {}

    /// Builds the styled body view for the given payment card input configuration.
    ///
    /// - Parameter configuration: The configuration provided by the `PaymentCardInput` environment.
    /// - Returns: A themed view containing the card number, expiry, and CVC fields.
    public func makeBody(configuration: Configuration) -> some View {
        ThemedBody(configuration: configuration)
    }

    private struct ThemedBody: View {
        @Environment(\.frameTheme) private var theme
        let configuration: Configuration

        private let rowHeight: CGFloat = 50.0
        @State private var isCardFocused = false

        private var borderColor: Color {
            isCardFocused ? theme.colors.fieldFocusStroke : theme.colors.surfaceStroke
        }

        private var borderWidth: CGFloat {
            isCardFocused ? 1.5 : 1
        }

        var body: some View {
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(theme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.medium)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .frame(height: rowHeight * 2)
                .overlay {
                    VStack(spacing: 0) {
                        configuration.cardNumberField
                            .frame(height: rowHeight)
                            .padding(.horizontal)
                        // Full-width inner rule — same weight/color as the outer border.
                        Rectangle()
                            .fill(borderColor)
                            .frame(height: borderWidth)
                        HStack(spacing: 0) {
                            configuration.expiryField
                                .frame(maxWidth: .infinity)
                                .padding(.leading)
                            // Full-height inner rule — same weight/color as the outer border.
                            Rectangle()
                                .fill(borderColor)
                                .frame(width: borderWidth)
                            configuration.cvcField
                                .frame(maxWidth: .infinity)
                                .padding(.leading)
                                .padding(.trailing)
                        }
                        .frame(height: rowHeight)
                    }
                }
                // Full-size probe: Evervault fields are SwiftUI TextFields that sit as siblings
                // in the UIKit tree, so we match focus by window-space frame intersection.
                .overlay {
                    CardInputFocusProbe(isFocused: $isCardFocused)
                        .allowsHitTesting(false)
                }
                .padding(.horizontal)
        }
    }
}

/// Reports focus for Evervault's SwiftUI `TextField`s by intersecting their UIKit frames with
/// this probe (which fills the card chrome). Descendant checks fail because the fields and
/// probe are siblings under separate SwiftUI overlay hosts.
private struct CardInputFocusProbe: UIViewRepresentable {
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isFocused: $isFocused)
    }

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        context.coordinator.isFocused = $isFocused
        uiView.coordinator = context.coordinator
    }

    final class Coordinator {
        var isFocused: Binding<Bool>

        init(isFocused: Binding<Bool>) {
            self.isFocused = isFocused
        }

        func setFocused(_ focused: Bool) {
            DispatchQueue.main.async {
                if self.isFocused.wrappedValue != focused {
                    self.isFocused.wrappedValue = focused
                }
            }
        }
    }

    final class ProbeView: UIView {
        weak var coordinator: Coordinator?
        private var observers: [NSObjectProtocol] = []

        override func didMoveToWindow() {
            super.didMoveToWindow()
            tearDownObservers()
            guard window != nil else { return }

            let center = NotificationCenter.default
            let beginNames = [
                UITextField.textDidBeginEditingNotification,
                UITextView.textDidBeginEditingNotification
            ]
            let endNames = [
                UITextField.textDidEndEditingNotification,
                UITextView.textDidEndEditingNotification
            ]
            for name in beginNames {
                observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                    self?.handleEditingChange(note.object as? UIView, began: true)
                })
            }
            for name in endNames {
                observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                    self?.handleEditingChange(note.object as? UIView, began: false)
                })
            }
        }

        deinit {
            tearDownObservers()
        }

        private func tearDownObservers() {
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
        }

        private func handleEditingChange(_ field: UIView?, began: Bool) {
            guard let field, window != nil, bounds.width > 0, bounds.height > 0 else { return }

            if began {
                if overlapsCard(field) {
                    coordinator?.setFocused(true)
                }
            } else {
                // Another card field may take focus on the next turn.
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if let responder = self.window?.frame_firstResponder, self.overlapsCard(responder) {
                        self.coordinator?.setFocused(true)
                    } else {
                        self.coordinator?.setFocused(false)
                    }
                }
            }
        }

        private func overlapsCard(_ field: UIView) -> Bool {
            guard let window else { return false }
            let fieldFrame = field.convert(field.bounds, to: window)
            // Slight inset expansion covers padding around Evervault's TextField.
            let cardFrame = convert(bounds, to: window).insetBy(dx: -8, dy: -8)
            return cardFrame.intersects(fieldFrame)
        }
    }
}

private extension UIView {
    var frame_firstResponder: UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let found = subview.frame_firstResponder { return found }
        }
        return nil
    }
}

#Preview {
    PaymentCardInput(cardData: .constant(PaymentCardData()))
        .paymentCardInputStyle(EncryptedPaymentCardInput())
}

#Preview("Dark") {
    PaymentCardInput(cardData: .constant(PaymentCardData()))
        .paymentCardInputStyle(EncryptedPaymentCardInput())
        .preferredColorScheme(.dark)
}
