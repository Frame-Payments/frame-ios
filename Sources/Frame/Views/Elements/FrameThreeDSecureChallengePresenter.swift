//
//  FrameThreeDSecureChallengePresenter.swift
//  Frame-iOS
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Presents an issuer 3D Secure challenge in a modal web view.
///
/// The page is built server-side and its URL already carries the redirect that marks the
/// challenge finished; this only loads it and watches for that redirect. The one-time code
/// stays between the cardholder and their issuer. Finishing is not the same as being charged —
/// ``ChargeIntentConfirmation`` asks the API for the verdict.
@MainActor
public final class FrameThreeDSecureChallengePresenter: NSObject {
    /// Supplies the challenge page. `next_action`'s `source` is a bare session id, not a URL,
    /// and building the page from it is a server responsibility.
    public typealias ChallengeURLProvider = @Sendable (FrameObjects.UseFrameSDK, FrameObjects.ChargeIntent) async throws -> URL

    private let challengeURLProvider: ChallengeURLProvider
    private let returnURLPrefix: String
    private weak var presentingViewController: UIViewController?

    /// Creates a challenge presenter.
    ///
    /// - Parameters:
    ///   - returnURLPrefix: The redirect marking the challenge finished. Must match the
    ///     `redirect` the URL was built with, or the sheet never dismisses.
    ///   - presentingViewController: Presents from here; defaults to the top-most controller.
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
    public nonisolated func presentChallenge(_ challenge: FrameObjects.UseFrameSDK,
                                             for intent: FrameObjects.ChargeIntent) async -> FrameThreeDSecureChallengeResult {
        let challengeURL: URL
        do {
            challengeURL = try await challengeURLProvider(challenge, intent)
        } catch {
            // No page means the challenge never ran, which is retryable.
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

            // Wrapped so the challenge is escapable. Abandoning it resolves as `.failed`, and
            // the caller still polls, because the charge may already have settled.
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

    /// The top-most presented controller in the active foreground scene.
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

/// Resumes a continuation at most once: resuming twice traps, and the completion,
/// load-failure, and dismissal callbacks are only mutually exclusive in principle.
private final class ContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>?

    init(_ continuation: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>) {
        self.continuation = continuation
    }

    func resume(with result: FrameThreeDSecureChallengeResult) {
        let claimed: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>? = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        claimed?.resume(returning: result)
    }
}

/// Reports an interactive dismissal, which SwiftUI does not surface here.
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
        // A no-op once another path has already resumed.
        if isBeingDismissed || parent == nil {
            onDismiss()
        }
    }
}
#endif
