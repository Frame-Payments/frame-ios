//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/11/24.
//

import Foundation
import SwiftUI

extension Binding where Value == String {
    public func max(_ limit: Int) -> Self {
        if self.wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(limit))
            }
        }
        return self
    }
}

extension Binding where Value == String? {
    public var orEmpty: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}
