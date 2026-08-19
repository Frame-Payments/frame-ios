//
//  Version.swift
//  Frame-iOS
//

import Foundation

/// Identifies this build of the Frame iOS SDK.
public enum FrameSDK {
    /// The SDK's released version.
    ///
    /// SPM exposes no version metadata to the code it builds, and the podspecs are
    /// Ruby, so this constant cannot be derived — it is hand-kept in sync with the
    /// git tag cut for the release (see `RELEASING.md`).
    public static let version = "4.4.0"

    /// The header naming this SDK build, sent on every Frame API request.
    ///
    /// Separate from the `User-Agent`, which stays the bare platform token: the API
    /// matches that token exactly in places (Sift's platform detector anchors on
    /// `/\AiOS\z/`), so appending a version there would silently reclassify native
    /// traffic as a browser. Reporting the version beside it leaves that matching
    /// untouched.
    ///
    /// Nothing reads this server-side yet — it exists so the version is on the wire
    /// and available when something wants it.
    static let versionHeader = "X-Frame-SDK-Version"
}
