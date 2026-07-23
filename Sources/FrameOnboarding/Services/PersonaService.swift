//
//  PersonaService.swift
//  Frame-iOS
//
//  Service that launches the Persona Inquiry SDK against a server-pre-created inquiry id and
//  bridges the delegate callbacks to async/await. Mirrors ProveAuthService's continuation pattern.
//
//  NOTE: Persona's `inquiryComplete` callback is best-effort and NOT authoritative for whether
//  verification passed — callers must confirm the result with the Frame backend (`/idv/complete`).
//  This service only reports how the Persona flow terminated (completed / canceled / errored).
//

import Foundation
import UIKit
import Persona2

/// How the Persona inquiry flow terminated, as reported by the client SDK.
///
/// - Important: `completed` does not mean the applicant passed verification. Persona's client-side
///   status is best-effort; the Frame backend (`/idv/complete`) is the source of truth. Treat
///   `completed` only as "the user finished the Persona flow, now go confirm server-side."
public enum PersonaInquiryOutcome: Sendable {
    /// The user finished the Persona flow. `status` is Persona's best-effort client status.
    case completed(inquiryId: String, status: String)
    /// The user canceled the Persona flow before finishing.
    case canceled(inquiryId: String?)
}

/// Wraps the Persona Inquiry SDK, launching an inquiry that was pre-created server-side and
/// bridging the `InquiryDelegate` callbacks into a single async result.
///
/// The SDK presents its own UI from the supplied `UIViewController`. Because presentation must
/// happen on the main thread, ``start(from:)`` hops to `@MainActor` before building and starting
/// the inquiry.
///
/// - Note: If the installed Persona SDK's API surface differs from the names used here
///   (`Inquiry.from(inquiryId:delegate:).build().start(from:)`, `InquiryDelegate`), adapt the
///   calls to the actual SDK — the async bridge below is otherwise unchanged.
public final class PersonaService: NSObject, @unchecked Sendable {
    private let inquiryId: String
    private var inquiry: Inquiry?
    private var once: PersonaOneTimeResume?

    /// Creates a service that will launch the Persona inquiry with the given identifier.
    /// - Parameter inquiryId: The pre-created Persona inquiry id (`inq_…`) from `/idv/session`.
    public init(inquiryId: String) {
        self.inquiryId = inquiryId
    }

    /// Presents the Persona inquiry from `viewController` and resumes once the flow terminates.
    ///
    /// - Parameter viewController: The view controller to present the Persona UI from.
    /// - Returns: How the flow terminated (``PersonaInquiryOutcome``).
    /// - Throws: A ``PersonaError`` if the Persona SDK reports an error.
    @MainActor
    public func start(from viewController: UIViewController) async throws -> PersonaInquiryOutcome {
        return try await withCheckedThrowingContinuation { continuation in
            let once = PersonaOneTimeResume(continuation: continuation)
            self.once = once
            // `self` acts as the InquiryDelegate; retain the built inquiry for the flow's lifetime.
            self.inquiry = Inquiry.from(inquiryId: inquiryId, delegate: self)
                .build()
            self.inquiry?.start(from: viewController)
        }
    }

    /// Reads and clears the one-time resume, then releases the retained inquiry. Must run on the
    /// main actor — `inquiry` and `once` are only ever set on the main actor in ``start(from:)``.
    @MainActor
    private func consumeResume() -> PersonaOneTimeResume? {
        let resume = once
        inquiry = nil
        once = nil
        return resume
    }
}

// MARK: - InquiryDelegate

extension PersonaService: InquiryDelegate {
    /// Called by the Persona SDK when the user finishes the inquiry flow. Resumes with
    /// ``PersonaInquiryOutcome/completed(inquiryId:status:)``.
    ///
    /// The Persona SDK invokes its delegate on the main thread; `MainActor.assumeIsolated` makes
    /// that guarantee explicit so the mutable `inquiry`/`once` state is touched only on the main
    /// actor. `PersonaOneTimeResume` additionally guards against a double-resume.
    ///
    /// - Important: `status` is best-effort and NOT authoritative for verification; confirm with
    ///   the Frame backend before treating the applicant as verified.
    /// - Parameters:
    ///   - inquiryId: The completed inquiry's identifier.
    ///   - status: Persona's best-effort client-side status string.
    ///   - fields: Field values collected during the inquiry.
    public func inquiryComplete(inquiryId: String, status: String, fields: [String: InquiryField]) {
        MainActor.assumeIsolated {
            consumeResume()?.resume(with: .success(.completed(inquiryId: inquiryId, status: status)))
        }
    }

    /// Called by the Persona SDK when the user cancels the inquiry. Resumes with
    /// ``PersonaInquiryOutcome/canceled(inquiryId:)``.
    /// - Parameters:
    ///   - inquiryId: The canceled inquiry's identifier, if one had been created.
    ///   - sessionToken: The session token for the canceled inquiry, if any.
    public func inquiryCanceled(inquiryId: String?, sessionToken: String?) {
        MainActor.assumeIsolated {
            consumeResume()?.resume(with: .success(.canceled(inquiryId: inquiryId)))
        }
    }

    /// Called by the Persona SDK when the inquiry errors. Resumes by throwing `error`.
    /// - Parameter error: The error reported by the Persona SDK.
    public func inquiryError(_ error: Error) {
        MainActor.assumeIsolated {
            consumeResume()?.resume(with: .failure(error))
        }
    }
}

// MARK: - One-time resume (guard against a delegate firing more than once)

private final class PersonaOneTimeResume: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<PersonaInquiryOutcome, Error>?

    init(continuation: CheckedContinuation<PersonaInquiryOutcome, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<PersonaInquiryOutcome, Error>) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        cont?.resume(with: result)
    }
}
