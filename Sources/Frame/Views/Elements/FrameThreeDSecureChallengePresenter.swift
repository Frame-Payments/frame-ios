//
//  FrameThreeDSecureChallengePresenter.swift
//  Frame-iOS
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Presents an issuer 3D Secure challenge in a modal web view.
///
/// The challenge page is built server-side and its URL already carries the redirect the
/// challenge returns to when it finishes; this presenter only loads that URL and watches for
/// the redirect. It deliberately does not collect, inspect, or forward anything the cardholder
/// types — the one-time code stays between the cardholder and their issuer.
///
/// Finishing the challenge is not the same as being charged. The presenter reports only that
/// the sheet is done; ``ChargeIntentConfirmation`` then asks the Frame API for the verdict.
@MainActor
public final class FrameThreeDSecureChallengePresenter: NSObject {
    /// Supplies the challenge page for a charge intent.
    ///
    /// The 3D Secure `source` in `next_action` is a bare session id, not a URL — turning it
    /// into a challenge page is a server responsibility, so the host app provides this.
    public typealias ChallengeURLProvider = @Sendable (FrameObjects.UseFrameSDK, FrameObjects.ChargeIntent) async throws -> URL

    private let challengeURLProvider: ChallengeURLProvider
    private let returnURLPrefix: String
    private weak var presentingViewController: UIViewController?

    /// Creates a challenge presenter.
    ///
    /// - Parameters:
    ///   - returnURLPrefix: The redirect that marks the challenge finished. Must match the
    ///     `redirect` the challenge URL was built with, or the sheet will never dismiss.
    ///   - presentingViewController: The controller to present the challenge from. When `nil`,
    ///     the key window's top-most controller is used.
    ///   - challengeURLProvider: Resolves a challenge session to a loadable page.
    public init(returnURLPrefix: String,
                presentingViewController: UIViewController? = nil,
                challengeURLProvider: @escaping ChallengeURLProvider) {
        self.returnURLPrefix = returnURLPrefix
        self.presentingViewController = presentingViewController
        self.challengeURLProvider = challengeURLProvider
        super.init()
    }
}

extension FrameThreeDSecureChallengePresenter: FrameThreeDSecureChallengePresenting {
    /// Presents the challenge and returns once it has finished, failed, or could not load.
    ///
    /// - Parameters:
    ///   - challenge: The challenge session to present.
    ///   - intent: The charge intent the challenge belongs to.
    /// - Returns: ``FrameThreeDSecureChallengeResult/completed`` once the challenge redirects,
    ///   ``FrameThreeDSecureChallengeResult/failed`` if the cardholder dismisses it, or
    ///   ``FrameThreeDSecureChallengeResult/unavailable`` if the page could not be loaded.
    public nonisolated func presentChallenge(_ challenge: FrameObjects.UseFrameSDK,
                                             for intent: FrameObjects.ChargeIntent) async -> FrameThreeDSecureChallengeResult {
        let challengeURL: URL
        do {
            challengeURL = try await challengeURLProvider(challenge, intent)
        } catch {
            // No page to show means the challenge never ran, which is retryable — distinct from
            // the cardholder failing one that did.
            return .unavailable
        }

        return await present(challengeURL: challengeURL)
    }

    @MainActor
    private func present(challengeURL: URL) async -> FrameThreeDSecureChallengeResult {
        guard let host = presentingViewController ?? Self.topMostViewController() else {
            return .unavailable
        }

        return await withCheckedContinuation { continuation in
            // Every path below routes through this, so the continuation resumes exactly once
            // even if a redirect and a dismissal race during teardown.
            let resumeOnce = ContinuationBox(continuation)

            let challenge = ThreeDSecureChallengeView(
                challengeURL: challengeURL,
                returnURLPrefix: returnURLPrefix,
                onFinish: { [weak host] in
                    host?.presentedViewController?.dismiss(animated: true)
                    resumeOnce.resume(with: .completed)
                },
                onLoadFailure: { [weak host] _ in
                    host?.presentedViewController?.dismiss(animated: true)
                    resumeOnce.resume(with: .unavailable)
                }
            )

            // Wrapped so the challenge is escapable. Abandoning it resolves the same way the
            // issuer reporting a failure does — the charge may still have settled, so the API
            // is still the authority and the caller still polls.
            let controller = ThreeDSecureHostingController(
                rootView: AnyView(NavigationStack {
                    challenge
                        .ignoresSafeArea(edges: .bottom)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { [weak host] in
                                    host?.presentedViewController?.dismiss(animated: true)
                                    resumeOnce.resume(with: .failed)
                                }
                            }
                        }
                }),
                onDismiss: { resumeOnce.resume(with: .failed) }
            )
            host.present(controller, animated: true)
        }
    }

    /// Finds the top-most presented controller in the active foreground scene.
    private static func topMostViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first(where: \.isKeyWindow)?
            .rootViewController

        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

/// Resumes a continuation at most once.
///
/// A continuation resumed twice traps, and the challenge's completion, load-failure, and
/// dismissal callbacks are only mutually exclusive in principle.
private final class ContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>?

    init(_ continuation: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>) {
        self.continuation = continuation
    }

    func resume(with result: FrameThreeDSecureChallengeResult) {
        // Claim the continuation under the lock so two callbacks racing during teardown
        // cannot both resume it.
        let claimed: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>? = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        claimed?.resume(returning: result)
    }
}

/// Reports an interactive dismissal, which SwiftUI alone does not surface here.
private final class ThreeDSecureHostingController: UIHostingController<AnyView> {
    private let onDismiss: () -> Void

    init(rootView: AnyView, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // A no-op once the completion or failure path has already resumed.
        if isBeingDismissed || parent == nil {
            onDismiss()
        }
    }
}
#endif
