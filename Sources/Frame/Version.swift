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
    public static let version = "4.5.0"

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

    /// The platform reported on emitted account events. Defaults to `"ios"`; overridden by
    /// ``setHostSDKInfo(platform:version:)`` when this build runs under a wrapper SDK.
    nonisolated(unsafe) static var eventPlatform = "ios"

    /// The wrapper SDK's version reported alongside emitted account events, if any.
    nonisolated(unsafe) static var hostSDKVersion: String?

    /// Tags subsequent account events as originating from a wrapper SDK (e.g. frame-react-native)
    /// instead of directly from this SDK.
    ///
    /// Internal API — not for integrator use. A wrapper SDK's own initialize() calls this once,
    /// before this SDK's `initialize(publishableKey:...)`, to override the `platform` and attach a
    /// `host_sdk_version` to every account event this SDK subsequently emits.
    ///
    /// - Parameters:
    ///   - platform: The wrapper's platform identifier (e.g. `"react_native"`).
    ///   - version: The wrapper SDK's own version.
    static func setHostSDKInfo(platform: String, version: String) {
        eventPlatform = platform
        hostSDKVersion = version
    }
}
