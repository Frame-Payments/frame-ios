//
//  CurrencyFormatter.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import Foundation

/// Formats integer cent amounts as currency strings for amount displays.
public class CurrencyFormatter {
    /// Shared formatter used by checkout, deposit, and payout.
    @MainActor public static let shared = CurrencyFormatter()
    
    let formatter = NumberFormatter()
    
    /// Formats `cents` as a currency string using the device locale.
    /// - Parameter cents: Amount in the currency's smallest unit.
    /// - Returns: A locale-formatted currency string.
    public func convertCentsToCurrencyString(_ cents: Int) -> String {
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let total = Double(cents) / 100.0
        return formatter.string(from: total as NSNumber) ?? ""
    }
}
