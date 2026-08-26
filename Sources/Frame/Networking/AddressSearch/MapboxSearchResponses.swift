//
//  MapboxSearchResponses.swift
//  Frame-iOS
//

import Foundation

/// Wire shapes for the Mapbox Search Box `/suggest` and `/retrieve` endpoints.
///
/// These are decoded with a dedicated decoder rather than `FrameNetworking.shared.jsonDecoder`,
/// because they are Mapbox's shapes rather than Frame's and must not follow Frame's conventions.
enum MapboxSearchResponses {
    struct SuggestResponse: Decodable {
        let suggestions: [Suggestion]

        struct Suggestion: Decodable {
            let mapboxId: String
            let name: String
            let placeFormatted: String?

            enum CodingKeys: String, CodingKey {
                case mapboxId = "mapbox_id"
                case name
                case placeFormatted = "place_formatted"
            }
        }
    }

    struct RetrieveResponse: Decodable {
        let features: [Feature]

        struct Feature: Decodable {
            let properties: Properties
        }

        struct Properties: Decodable {
            let name: String?
            let addressLine1: String?
            let context: Context?

            enum CodingKeys: String, CodingKey {
                case name
                case addressLine1 = "address"
                case context
            }
        }

        /// Mapbox nests each administrative level under its own key rather than returning a flat
        /// address, so the components arrive one object per level.
        struct Context: Decodable {
            let place: Component?
            let region: Component?
            let postcode: Component?
            let country: Component?
        }

        struct Component: Decodable {
            let name: String?
            /// The short code for the level, e.g. `US-CA` for a region or `US` for a country.
            /// Absent for levels that have no code, such as a city.
            let regionCode: String?
            let countryCode: String?

            enum CodingKeys: String, CodingKey {
                case name
                case regionCode = "region_code"
                case countryCode = "country_code"
            }
        }
    }
}
