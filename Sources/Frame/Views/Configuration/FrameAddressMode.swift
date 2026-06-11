//
//  FrameAddressMode.swift
//  Frame-iOS
//

import Foundation

/// Controls whether an address field is required, optional, or hidden in a Frame UI component.
public enum FrameAddressMode {
    /// The address field must be filled in before the user can proceed.
    case required
    /// The address field is shown but may be left blank.
    case optional
    /// The address field is not displayed to the user.
    case hidden
}
