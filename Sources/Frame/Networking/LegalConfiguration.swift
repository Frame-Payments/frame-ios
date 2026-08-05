import Foundation

/// Sync accessors for Frame's legal document URLs (Privacy Policy, Terms of Service, Platform
/// Agreement, and Card-Based Cash Terms & Conditions).
///
/// URLs are fetched from the Frame configuration API at SDK init and cached in the keychain,
/// then read synchronously by SDK UI. If the fetch fails and no cached value is present, each
/// accessor falls back to a hardcoded URL so the SDK never renders a broken link.
public enum LegalConfiguration {
    private static let fallbackPrivacyURL = URL(string: "https://framepayments.com/legal/privacy")!
    private static let fallbackTermsURL = URL(string: "https://framepayments.com/legal/terms")!
    private static let fallbackPlatformAgreementURL = URL(string: "https://framepayments.com/legal/platform-agreement")!
    private static let fallbackCBCTermsURL = URL(string: "https://framepayments.com/legal/cbc-terms-and-conditions")!

    static func prefetch() async {
        _ = try? await ConfigurationAPI.getLegalConfiguration()
    }

    private static func cached() -> ConfigurationResponses.GetLegalConfigurationResponse? {
        guard let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.legal.rawValue) else {
            return nil
        }
        return try? FrameNetworking.shared.jsonDecoder.decode(
            ConfigurationResponses.GetLegalConfigurationResponse.self,
            from: data
        )
    }

    private static func url(_ raw: String?, fallback: URL) -> URL {
        if let raw, let url = URL(string: raw) { return url }
        return fallback
    }

    /// URL of Frame's Privacy Policy, sourced from the configuration API cache or falling back
    /// to a bundled default.
    public static var privacyURL: URL {
        url(cached()?.privacyUrl, fallback: fallbackPrivacyURL)
    }

    /// URL of Frame's Terms of Service, sourced from the configuration API cache or falling back
    /// to a bundled default.
    public static var termsURL: URL {
        url(cached()?.termsUrl, fallback: fallbackTermsURL)
    }

    /// URL of Frame's Platform Agreement, sourced from the configuration API cache or falling back
    /// to a bundled default.
    public static var platformAgreementURL: URL {
        url(cached()?.platformAgreementUrl, fallback: fallbackPlatformAgreementURL)
    }

    /// URL of Frame's Card-Based Cash (CBC) Terms & Conditions, sourced from the configuration
    /// API cache or falling back to a bundled default.
    public static var cbcTermsURL: URL {
        url(cached()?.cbcTermsAndConditions, fallback: fallbackCBCTermsURL)
    }
}
