//
//  FrameThreeDSecureChallengePresenter.swift
//  Frame-iOS
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Presents an issuer 3D Secure challenge in a modal web view.
///
/// The page comes from `next_action.use_frame_sdk.challenge_url`, already carrying the redirect
/// that marks the challenge finished; this loads it and watches for that redirect. The one-time
/// code stays between the cardholder and their issuer. Finishing is not the same as being
/// charged — ``ChargeIntentConfirmation`` asks the API for the verdict.
@MainActor
public final class FrameThreeDSecureChallengePresenter: NSObject {
    /// The redirect the API builds its challenge URLs against.
    private static let callbackPathComponent = "evervault_3ds_callbacks"

    private weak var presentingViewController: UIViewController?

    /// Creates a challenge presenter.
    ///
    /// - Parameter presentingViewController: Presents from here; defaults to the top-most
    ///   controller when `nil`.
    public init(presentingViewController: UIViewController? = nil) {
        self.presentingViewController = presentingViewController
        super.init()
    }
}

extension FrameThreeDSecureChallengePresenter: FrameThreeDSecureChallengePresenting {
    /// Presents the challenge and returns once it has finished, failed, or could not load.
    public nonisolated func presentChallenge(_ challenge: FrameObjects.UseFrameSDK,
                                             for intent: FrameObjects.ChargeIntent) async -> FrameThreeDSecureChallengeResult {
        guard let challengeURL = challenge.challengeURL else {
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
                returnURLPathComponent: Self.callbackPathComponent,
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
