//
//  FrameFontRegistration.swift
//  Frame-iOS
//
//  Registers bundled Soehne (Söhne) fonts from the SDK resource bundle at runtime.
//  SPM does not inject UIAppFonts; registration happens on first theme access.
//

import CoreText
import Foundation
import SwiftUI

enum FrameFontRegistration {
    private static let lock = NSLock()
    private static var didRegister = false

    /// PostScript names for the bundled Soehne weight files.
    enum Name {
        static let buch = "Sohne-Buch"
        static let kraftig = "Sohne-Kraftig"
        static let dreiviertelfett = "Sohne-Dreiviertelfett"
        static let fett = "Sohne-Fett"
    }

    static func registerIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didRegister else { return }
        didRegister = true

        let fileNames = [
            "soehne-buch",
            "soehne-kraftig",
            "soehne-dreiviertelfett",
            "soehne-fett"
        ]
        for name in fileNames {
            guard let url = FrameResources.module.url(forResource: name, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func soehne(size: CGFloat, postScriptName: String) -> Font {
        registerIfNeeded()
        return .custom(postScriptName, size: size)
    }
}
