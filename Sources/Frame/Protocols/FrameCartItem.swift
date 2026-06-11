//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import Foundation

/// A protocol that represents a single item in a Frame payment cart.
///
/// Conform your product or order-line model to `FrameCartItem` so the SDK can
/// display it in checkout UI and include it in payment requests.
public protocol FrameCartItem: Identifiable {
    /// A unique identifier for the cart item.
    var id: String { get set }
    /// A URL string pointing to the item's display image.
    var imageURL: String { get set }
    /// The human-readable name or description of the item.
    var title: String { get set }
    /// The price of the item expressed in the smallest currency unit (e.g. cents for USD).
    var amountInCents: Int { get set }
}
