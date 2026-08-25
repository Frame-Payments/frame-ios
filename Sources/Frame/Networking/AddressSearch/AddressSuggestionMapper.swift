//
//  AddressSuggestionMapper.swift
//  Frame-iOS
//

import Foundation

/// Turns a retrieved Mapbox feature into a ``FrameObjects/BillingAddress``.
enum AddressSuggestionMapper {
    /// Builds a billing address from a retrieved feature.
    ///
    /// Address line 2 is never populated: Mapbox does not reliably return apartment or unit, so
    /// the field stays as the user left it.
    static func billingAddress(
        from feature: MapboxSearchResponses.RetrieveResponse.Feature
    ) -> FrameObjects.BillingAddress {
        let properties = feature.properties
        let context = properties.context

        let countryCode = context?.country?.countryCode?.uppercased()

        return FrameObjects.BillingAddress(
            city: context?.place?.name,
            country: countryCode,
            state: subregion(from: context?.region, countryCode: countryCode),
            postalCode: context?.postcode?.name ?? "",
            addressLine1: properties.addressLine1 ?? properties.name
        )
    }

    /// Resolves the subregion to the form the SDK's validation expects.
    ///
    /// `Validators.validateSubregion` runs against the raw value and matches it against the
    /// two-letter codes for countries that enumerate them, so a full name like `California` has to
    /// become `CA` here. `BillingAddressViewModel.normalize()` runs only after validation, which
    /// is too late to rescue it.
    ///
    /// Mapbox's `region_code` is the level's short code — `US-CA` in some responses, `CA` in
    /// others — so the country prefix is dropped when present. When Mapbox sends no code at all,
    /// the name is matched against the SDK's own subregion list before falling back to the raw
    /// value, which keeps free-text countries working as they do today.
    private static func subregion(
        from region: MapboxSearchResponses.RetrieveResponse.Component?,
        countryCode: String?
    ) -> String? {
        guard let region else { return nil }

        if let code = region.regionCode?.split(separator: "-").last.map(String.init), !code.isEmpty {
            return code.uppercased()
        }

        guard let name = region.name else { return nil }
        guard let countryCode, let subregions = AddressSubregions.subregions(forCountry: countryCode) else {
            return name
        }

        let match = subregions.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        return match?.code ?? name
    }
}
