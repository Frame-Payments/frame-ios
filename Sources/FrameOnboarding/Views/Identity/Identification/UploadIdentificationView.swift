//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/12/25.
//

import SwiftUI
import UIKit
import Frame

enum UploadDocSide: String {
    case frontPhoto = "Front Photo"
    case backPhoto = "Back Photo"
    case selfiePhoto = "Take a Selfie"
    
    var fieldName: FileUpload.FieldName {
        switch self {
        case .frontPhoto:
            return .front
        case .backPhoto:
            return .back
        case .selfiePhoto:
            return .selfie
        }
    }
}

struct UploadIdentificationView: View {
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var showUploadInputs = false
    @State private var documentsAdded: [UploadDocSide: Image] = [:]
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var currentSelectedDoc: FileUpload.FieldName = .front
    @State private var enabledContinueButton = true
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    
    var body: some View {
        VStack {
            if showUploadInputs {
                uploadIdentityView
            } else {
                identityIntro
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            StructuredCameraView(cameraImage: $cameraImage, photoType: currentSelectedDoc)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: cameraImage) { oldValue, newValue in
            guard let cameraImage else { return }
            
            self.onboardingContainerViewModel.filesToUpload.removeAll(where: { $0.fieldName == currentSelectedDoc })
            self.onboardingContainerViewModel.filesToUpload.append(FileUpload(image: cameraImage, fieldName: currentSelectedDoc))
            
        }
    }
    
    var identityIntro: some View {
        VStack(spacing: 15.0) {
            Spacer()
            Image("upload-icon", bundle: FrameResources.module)
            Text("Upload a photo of your ID")
                .font(.system(size: 18.0))
                .fontWeight(.semibold)
            Text("We’ll ask you to take photos of both the front and back to confirm your information.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(FrameColors.secondaryTextColor)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                self.showUploadInputs.toggle()
            }
            .padding(.bottom)
        }
    }
    
    var uploadIdentityView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Upload Your ID") {
                self.showUploadInputs.toggle()
            }
            Text("Take photos of the front and back of your government ID.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(FrameColors.secondaryTextColor)
                .padding(.horizontal, 15.0)
                .padding(.bottom, 8.0)
            ScrollView {
                listIdentificationOptionsView
                listSelfieOptionsView
            }
            Spacer()
            ContinueButton(buttonText: "Submit", enabled: $enabledContinueButton) {
                self.enabledContinueButton = false
                self.uploadDocsThenContinue()
            }
            .padding(.bottom)
            .opacity(onboardingContainerViewModel.checkIfCustomerCanContinueWithDocs() ? 1.0 : 0.3)
            .disabled(!onboardingContainerViewModel.checkIfCustomerCanContinueWithDocs())
        }
    }
    
    var listIdentificationOptionsView: some View {
        Group {
            headerScrollTitles(name: "License, Passport or Government Id")
            identificationMethodView(docSide: .frontPhoto)
            identificationMethodView(docSide: .backPhoto)
        }
    }
    
    var listSelfieOptionsView: some View {
        Group {
            headerScrollTitles(name: "Selfie")
            identificationMethodView(docSide: .selfiePhoto)
        }
    }
    
    func headerScrollTitles(name: String) -> some View {
        HStack {
            Text(name)
                .bold()
                .font(.system(size: 14.0))
                .padding(.horizontal)
                .padding(.vertical, 8.0)
            Spacer()
        }
    }
    
    func identificationMethodView(docSide: UploadDocSide) -> some View {
        HStack {
            Image(onboardingContainerViewModel.filesToUpload.contains(where: { $0.fieldName == docSide.fieldName }) ? "filled-identification-card" : "identification-card", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            Text(docSide.rawValue)
                .bold()
                .font(.system(size: 14.0))
                .padding(.bottom, 1.0)
            Spacer()
            Image("right-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            self.currentSelectedDoc = docSide.fieldName
            self.showCamera.toggle()
        }
    }
    
    func uploadDocsThenContinue() {
        Task {
            await onboardingContainerViewModel.uploadIdentificationDocuments()
            self.continueToNextStep.toggle()
        }
    }
}

#Preview {
    UploadIdentificationView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: ""), continueToNextStep: .constant(false), returnToPreviousStep: .constant(false))
}
