//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/19/25.
//

import SwiftUI
import Frame_iOS

struct UserIdentificationView: View {
//    @StateObject private var kycViewModel = KYCViewModel()
    @State private var isPresentingSDK = false
    @State private var message = ""
    @State private var showIdentityInputs: Bool = false
    
    var body: some View {
        VStack {
            identityIntro
        }
    }
    
    var identityIntro: some View {
        VStack(spacing: 15.0) {
            Spacer()
            Image("shield-icon", bundle: FrameResources.module)
            Text("Verify Your Identity")
                .font(.system(size: 18.0))
                .fontWeight(.semibold)
            Text("We’re required by law to verify your identity. This takes about 2 minutes and you’ll need a Government ID and a selfie.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                isPresentingSDK.toggle()
            }
        }
    }
}

#Preview {
    UserIdentificationView()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
