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
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let total = cents / 100
        return formatter.string(from: total as NSNumber) ?? ""
    }
}
