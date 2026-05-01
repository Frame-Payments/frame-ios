//
//  AddressFormat.swift
//  Frame-iOS
//

import Foundation
import UIKit

public struct AddressFormat: Equatable {
    public let stateLabel: String
    public let postalLabel: String
    public let postalKeyboard: UIKeyboardType
    public let stateMaxLength: Int?

    public init(stateLabel: String, postalLabel: String, postalKeyboard: UIKeyboardType, stateMaxLength: Int?) {
        self.stateLabel = stateLabel
        self.postalLabel = postalLabel
        self.postalKeyboard = postalKeyboard
        self.stateMaxLength = stateMaxLength
    }

    private static let formats: [String: AddressFormat] = [
        "US": AddressFormat(stateLabel: "State", postalLabel: "Zip Code", postalKeyboard: .numberPad, stateMaxLength: 2),
        "CA": AddressFormat(stateLabel: "Province", postalLabel: "Postal Code", postalKeyboard: .default, stateMaxLength: 2),
        "GB": AddressFormat(stateLabel: "County", postalLabel: "Postcode", postalKeyboard: .default, stateMaxLength: nil),
        "AU": AddressFormat(stateLabel: "State", postalLabel: "Postcode", postalKeyboard: .numberPad, stateMaxLength: nil),
        "DE": AddressFormat(stateLabel: "State", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "FR": AddressFormat(stateLabel: "Region", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "NL": AddressFormat(stateLabel: "Province", postalLabel: "Postcode", postalKeyboard: .default, stateMaxLength: nil),
        "JP": AddressFormat(stateLabel: "Prefecture", postalLabel: "Postal Code", postalKeyboard: .default, stateMaxLength: nil),
        "MX": AddressFormat(stateLabel: "State", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "IN": AddressFormat(stateLabel: "State", postalLabel: "PIN Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "IE": AddressFormat(stateLabel: "County", postalLabel: "Eircode", postalKeyboard: .default, stateMaxLength: nil),
        "NZ": AddressFormat(stateLabel: "Region", postalLabel: "Postcode", postalKeyboard: .numberPad, stateMaxLength: nil),
        "BR": AddressFormat(stateLabel: "State", postalLabel: "CEP", postalKeyboard: .numberPad, stateMaxLength: nil),
        "IT": AddressFormat(stateLabel: "Province", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "ES": AddressFormat(stateLabel: "Province", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "SG": AddressFormat(stateLabel: "Region", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil)
    ]

    private static let `default` = AddressFormat(stateLabel: "State",
                                                 postalLabel: "Postal Code",
                                                 postalKeyboard: .default,
                                                 stateMaxLength: nil)

    public static func format(forCountry alpha2: String) -> AddressFormat {
        formats[alpha2.uppercased()] ?? .default
    }
}
