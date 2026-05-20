import Foundation

public extension FrameObjects.PaymentCard {
    // Bundled asset name for this card's brand logo. Falls back to a generic
    // card icon when the brand isn't one we ship a dedicated asset for.
    //
    // API brand strings vary in spelling ("american-express", "americanex",
    // "master-card", etc.), so we match a short prefix per supported brand.
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
