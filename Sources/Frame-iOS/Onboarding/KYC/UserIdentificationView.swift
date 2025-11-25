//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/19/25.
//

import SwiftUI
import Persona2

struct UserIdentificationView: View {
    @StateObject private var kycViewModel = KYCViewModel()
    @State private var isPresentingSDK = false
    @State private var message = ""
    
    var body: some View {
        VStack(spacing: 30.0) {
            Text("Verify Your Identity")
                .font(.title)
                .bold()
            Text("We're required by law to verify your identity. This takes about 2 minutes and you'll need")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20.0)
            HStack {
                Image(systemName: "doc.append")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30.0, height: 30.0)
                VStack(alignment: .leading, spacing: 7.0) {
                    Text("Government ID")
                        .bold()
                    Text("(driver's license, ID Card, or passport)")
                }
                Spacer()
            }
            .padding(.horizontal, 20.0)
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30.0, height: 30.0)
                Text("A well-lit place to take a selfie")
                    .bold()
                Spacer()
            }
            .padding(.horizontal, 20.0)
            Spacer()
            Button {
                isPresentingSDK.toggle()
            } label: {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(Color.init(hex: "#325054"))
                    .overlay {
                        Text("Start Verification")
                            .bold()
                            .foregroundColor(.white)
                    }
            }
            .frame(height: 50.0)
            .padding()
        }
        .fullScreenCover(
                        isPresented: $isPresentingSDK,
                        onDismiss: {},
                        content: {
                            InquirySDKWrapper(
                                inquiryComplete: { inquiryId, status, fields in
                                    self.message = """
                                        Inquiry Complete
                                        Inquiry ID: \(inquiryId)
                                        Status: \(String(describing: status))
                                    """
                                    print(self.message)
                                },
                                inquiryCanceled: { inquiryId, sessionToken in
                                    self.message = "🤷‍♀️ Inquiry Cancelled"
                                    print(self.message)
                                },
                                inquiryErrored: { error in
                                    self.message = """
                                        💀 Inquiry Error
                                        \(error.localizedDescription)
                                    """
                                    print(self.message)
                                }
                            )
                        }
                    )
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
