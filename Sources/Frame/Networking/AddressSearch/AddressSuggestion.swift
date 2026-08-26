//
//  AddressSuggestion.swift
//  Frame-iOS
//

import Foundation

/// One address the user can pick from the autocomplete list.
///
/// A suggestion carries only what the list needs to draw a row plus the identifier used to
/// retrieve the full address. Mapbox returns the components on the retrieve call, not on
/// suggest, so a suggestion alone cannot fill a form.
public struct AddressSuggestion: Identifiable, Equatable, Sendable {
    /// Identifies the suggestion within its search session.
    public let id: String
    /// The first line of the row, typically the street address.
    public let title: String
    /// The second line of the row, typically city, state, and country.
    public let subtitle: String

    public init(id: String, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}
