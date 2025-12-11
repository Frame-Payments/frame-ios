//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/11/25.
//

import SwiftUI
import Frame_iOS

struct PageHeaderView: View {
    let headerTitle: String
    let buttonAction: () -> ()
    
    var body: some View {
        HStack(alignment: .center) {
            Button {
                buttonAction()
            } label: {
                Image("left-chevron", bundle: FrameResources.module)
            }
            .padding()

            Spacer()
            Text(headerTitle)
                .bold()
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    PageHeaderView(headerTitle: "Example Title", buttonAction: {})
}
