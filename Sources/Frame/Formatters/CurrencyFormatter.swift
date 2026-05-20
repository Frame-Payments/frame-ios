//
//  CurrencyFormatter.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import Foundation

class CurrencyFormatter {
    @MainActor static let shared = CurrencyFormatter()
    
    let formatter = NumberFormatter()
    
    func convertCentsToCurrencyString(_ cents: Int) -> String {
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let total = Double(cents) / 100.0
        return formatter.string(from: total as NSNumber) ?? ""
    }
}
