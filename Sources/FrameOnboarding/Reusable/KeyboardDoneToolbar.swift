//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/15/26.
//

import SwiftUI

struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

struct KeyboardSpacing: View {
    var spacingHeight: CGFloat = 280.0
    
    var body: some View {
        Spacer().frame(height: spacingHeight)
    }
}

extension View {
    func keyboardDoneToolbar() -> some View {
        modifier(KeyboardDoneToolbar())
    }
}
