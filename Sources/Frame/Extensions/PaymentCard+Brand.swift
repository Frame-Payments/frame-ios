import Foundation

public extension FrameObjects.PaymentCard {
    /// The bundled asset name for this card's brand logo.
    ///
    /// Returns the image asset name corresponding to the card's brand. Falls back to a generic
    /// card icon when the brand is not one the SDK ships a dedicated asset for.
    ///
    /// API brand strings vary in spelling (e.g. `"american-express"`, `"americanex"`,
    /// `"master-card"`), so the implementation matches a short prefix per supported brand.
    ///
    /// - Returns: A string identifying the image asset to use for the card brand logo.
    var brandIconName: String {
        let normalized = brand.lowercased()
        let aliases: [(prefix: String, asset: String)] = [
            ("ame", "amex"),
            ("master", "mastercard"),
            ("vi", "visa"),
            ("dis", "discover")
        ]
        for (prefix, asset) in aliases where normalized.hasPrefix(prefix) {
            return asset
        }
        return "CreditCardIcon"
    }
}
