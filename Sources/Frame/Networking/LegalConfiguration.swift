import Foundation

public enum LegalConfiguration {
    private static let fallbackPrivacyURL = URL(string: "https://framepayments.com/legal/privacy")!
    private static let fallbackTermsURL = URL(string: "https://framepayments.com/legal/terms")!
    private static let fallbackPlatformAgreementURL = URL(string: "https://framepayments.com/legal/platform-agreement")!
    private static let fallbackCBCTermsURL = URL(string: "https://framepayments.com/legal/cbc-terms")!

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

    public static var privacyURL: URL {
        url(cached()?.privacyUrl, fallback: fallbackPrivacyURL)
    }

    public static var termsURL: URL {
        url(cached()?.termsUrl, fallback: fallbackTermsURL)
    }

    public static var platformAgreementURL: URL {
        url(cached()?.platformAgreementUrl, fallback: fallbackPlatformAgreementURL)
    }

    public static var cbcTermsURL: URL {
        url(cached()?.cbcTermsAndConditions, fallback: fallbackCBCTermsURL)
    }
}
