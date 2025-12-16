//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/12/25.
//

import SwiftUI
import Frame_iOS

enum UploadDocSide: String {
    case frontPhoto = "Front Photo"
    case backPhoto = "Back Photo"
    case selfiePhoto = "Take a Selfie"
}

struct UploadIdentificationView: View {
    @State private var showUploadInputs: Bool = false
    @State private var documentsAdded: [UploadDocSide: Image] = [:]
    @State private var showCamera = false
    @State private var cameraImage: Image?
    @State private var currentSelectedDoc: UploadDocSide = .frontPhoto
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    
    let idTypes: [String] = ["Driver's License", "State ID", "Military ID", "Passport"]
    let restrictedCountries: [String] = ["Iran", "Russia", "North Korea", "Syria", "Cuba",
                                         "Democratic Republic of Congo", "Iraq", "Libya",
                                         "Mali", "Nicaragua", "Sudan", "Venezuela", "Yemen"]
    
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
            self.documentsAdded.updateValue(cameraImage, forKey: currentSelectedDoc)
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
                .foregroundColor(secondaryTextColor)
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
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 15.0)
                .padding(.bottom, 8.0)
            listIdentificationOptionsView
            Spacer()
            ContinueButton(buttonText: "Submit", enabled: .constant(true)) {
                self.continueToNextStep.toggle()
            }
            .padding(.bottom)
        }
    }
    
    var listIdentificationOptionsView: some View {
        ScrollView {
            headerScrollTitles(name: "License, Passport or Government Id")
            identificationMethodView(docSide: .frontPhoto)
            identificationMethodView(docSide: .backPhoto)
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
            Image(documentsAdded.keys.contains(docSide) ? "filled-identification-card" : "identification-card", bundle: FrameResources.module)
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
            self.currentSelectedDoc = docSide
            self.showCamera.toggle()
        }
    }
}

#Preview {
    UploadIdentificationView(continueToNextStep: .constant(false), returnToPreviousStep: .constant(false))
}
