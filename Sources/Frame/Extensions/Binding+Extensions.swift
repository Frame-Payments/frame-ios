//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/11/24.
//

import Foundation
import SwiftUI

/// Convenience extensions on `Binding<String>` for input validation in SDK form fields.
extension Binding where Value == String {
    /// Enforces a maximum character limit on the bound string, trimming any excess characters asynchronously.
    ///
    /// - Parameter limit: The maximum number of characters allowed in the bound string.
    /// - Returns: The same binding, allowing this modifier to be chained with other SwiftUI view modifiers.
    public func max(_ limit: Int) -> Self {
        if self.wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(limit))
            }
        }
        return self
    }
}

/// Convenience extensions on `Binding<String?>` for bridging optional strings to non-optional SwiftUI bindings.
extension Binding where Value == String? {
    /// A non-optional binding that reads the wrapped optional as an empty string when `nil` and writes back as-is.
    public var orEmpty: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}
