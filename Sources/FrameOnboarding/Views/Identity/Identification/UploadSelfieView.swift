//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/15/25.
//

import SwiftUI
import Frame

struct UploadSelfieView: View {
    @State private var showCamera = false
    @State private var cameraImage: Image?
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    
    var body: some View {
        VStack {
            identityIntro
        }
        .fullScreenCover(isPresented: $showCamera) {
            StructuredCameraView(cameraImage: $cameraImage, photoType: .selfiePhoto)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: cameraImage) { oldValue, newValue in
            guard let cameraImage else { return }
            
            // Continue to processing screen and upload the images.
        }
    }
    
    var identityIntro: some View {
        VStack(spacing: 15.0) {
            Spacer()
            Image("person-icon", bundle: FrameResources.module)
            Text("Take a Selfie")
                .font(.system(size: 18.0))
                .fontWeight(.semibold)
            Text("Position yourself in the center of the screen and then move your head left and right to show both sides.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                self.showCamera.toggle()
            }
            .padding(.bottom)
        }
    }
}

#Preview {
    UploadSelfieView(continueToNextStep: .constant(false), returnToPreviousStep: .constant(false))
}
