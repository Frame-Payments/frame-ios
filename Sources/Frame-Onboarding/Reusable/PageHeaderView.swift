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
            .frame(width: 50.0, height: 50.0)

            Spacer()
            Text(headerTitle)
                .bold()
            Spacer()
            Rectangle()
                .fill(.clear)
                .frame(width: 50.0, height: 50.0)
        }
    }
}

#Preview {
    PageHeaderView(headerTitle: "Example Title", buttonAction: {})
}
