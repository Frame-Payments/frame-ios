//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import Foundation

public protocol FrameCartItem: Identifiable {
    var id: String { get set }
    var imageURL: String { get set }
    var title: String { get set }
    var amountInCents: Int { get set }
}
