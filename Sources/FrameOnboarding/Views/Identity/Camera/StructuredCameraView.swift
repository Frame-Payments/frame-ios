//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/15/25.
//

import SwiftUI
import Frame

struct StructuredCameraView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var cameraService = CameraService()
    @Binding var cameraImage: UIImage?
    @State var photoType: FileUpload.FieldName
    
    var body: some View {
        ZStack {
            if cameraService.captureSession != nil {
                CameraPreviewView(cameraService: cameraService)
                    .edgesIgnoringSafeArea(.all)
            }
            if photoType == .selfie {
                GeometryReader { geo in
                   let holeSize = CGSize(width: 330, height: 400)
                   let holeRect = CGRect(
                       x: (geo.size.width - holeSize.width) / 2,
                       y: 180, // adjust this to position the oval
                       width: holeSize.width,
                       height: holeSize.height
                   )

                   Path { p in
                       p.addRect(CGRect(origin: .zero, size: geo.size))
                       p.addEllipse(in: holeRect)
                   }
                   .fill(.black.opacity(0.8), style: FillStyle(eoFill: true))
                   .compositingGroup()

                   Ellipse()
                       .path(in: holeRect)
                       .stroke(.green, lineWidth: 3)
                    
                    VStack {
                        PageHeaderView(useCloseButton: true, headerTitle: photoType.rawValue) {
                            self.dismiss()
                        }
                        .padding(.top, 50.0)
                        Spacer()
                        Button {
                            cameraService.capturePhoto()
                        } label: {
                            Image("camera-button", bundle: FrameResources.module)
                        }
                        .padding(20.0)
                    }
                }.ignoresSafeArea()
            } else {
                VStack(spacing: 0) {
                    Rectangle().fill(.black.opacity(0.8))
                        .frame(height: 180.0)
                        .overlay {
                            VStack {
                                Spacer()
                                PageHeaderView(useCloseButton: true, headerTitle: photoType.rawValue) {
                                    self.dismiss()
                                }
                                Text("Place the back of your ID in the frame and snap a photo. Make sure your ID is clear and legible.")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14.0))
                                    .padding(.horizontal, 10.0)
                            }
                            .padding(.bottom, 30.0)
                        }
                    HStack(spacing: 0) {
                        Rectangle().fill(.black.opacity(0.8))
                            .frame(width: 20.0)
                        Rectangle().fill(.clear)
                            .border(Color.green, width: 3.0)
                        Rectangle().fill(.black.opacity(0.8))
                            .frame(width: 20.0)
                    }
                    .frame(height: 220.0)
                    Rectangle().fill(.black.opacity(0.8))
                        .frame(maxHeight: .infinity)
                        .overlay {
                            VStack {
                                Spacer()
                                Button {
                                    cameraService.capturePhoto()
                                } label: {
                                    Image("camera-button", bundle: FrameResources.module)
                                }
                                .padding(20.0)
                            }
                        }
                }
            }
        }
        .onAppear {
            cameraService.setupAndStartSession(useFrontCamera: photoType == .selfie)
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onChange(of: cameraService.capturedImage, { oldValue, newValue in
            if let capImage = cameraService.capturedImage {
                self.cameraImage = capImage
                self.dismiss()
            }
        })
        .ignoresSafeArea()
    }
}

#Preview {
    StructuredCameraView(cameraImage: .constant(nil), photoType: .back)
}
