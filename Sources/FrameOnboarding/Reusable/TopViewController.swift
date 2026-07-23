//
//  TopViewController.swift
//  Frame-iOS
//
//  Shared helper for resolving the top-most presented view controller, used when a SwiftUI
//  view needs a UIViewController to present a UIKit-based SDK flow (Plaid, Persona, …) from.
//

import UIKit

extension UIApplication {
    /// The top-most presented view controller of the foreground-active window scene's key window.
    ///
    /// `connectedScenes` is an unordered set that can include background/unattached scenes, so this
    /// deliberately selects the `.foregroundActive` scene and its key window rather than taking the
    /// first arbitrary scene. Returns `nil` when no foreground-active scene with a root view
    /// controller exists (e.g. the app is backgrounded), so callers can bail rather than present
    /// from a detached controller that is in no window hierarchy.
    var topViewController: UIViewController? {
        let keyWindow = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        guard var top = keyWindow?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
