//
//  PKPaymentButtonWrapper.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.
//

import SwiftUI
import PassKit

struct PKPaymentButtonWrapper: UIViewRepresentable {
    var buttonType: PKPaymentButtonType
    var buttonStyle: PKPaymentButtonStyle
    var action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.action = action
    }

    class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}
