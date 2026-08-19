import Foundation

// MARK: - SessionManagerError

/// Failures raised while establishing a Sonar fraud-detection session.
public enum SessionManagerError: Error, Equatable {
    /// Fingerprint returned neither a visitor id nor a sealed result, so no session can be created.
    ///
    /// - Note: Named for the visitor id alone because it predates sealed results and
    ///   is public API. An activated environment withholds the visitor id normally,
    ///   which on its own is not this error.
    case missingVisitorId

    /// The session create or update request failed.
    case requestFailed(NetworkingError)
}

// MARK: - SessionManager

/// Manages the lifecycle of a Sonar fraud-detection session, including creation, refresh, and
/// local persistence.
///
/// The server resolves a payment's session *through the Frame account*, so a session only backs a
/// payment once it has been associated with one; a session created without an account is invisible
/// to risk checks and the payment is rejected with `sonar_session_required`. Sessions also go stale:
/// the server requires the session's latest device event to be recent, and only a create or update
/// call records one.
///
/// Call ``ensureSession(accountId:)`` before taking a payment and await the result.
public actor SessionManager {
    /// The shared session manager used by the SDK.
    public static let shared = SessionManager()

    /// Sits well inside the server's freshness window: refreshing early is cheap, being slightly
    /// late fails the payment.
    private static let refreshInterval: TimeInterval = 15 * 60

    /// How often the keep-alive re-touches the live session. Deliberately shorter than
    /// ``refreshInterval`` so a refresh always lands before the window closes, rather than the
    /// window expiring and the refresh falling onto the payment's critical path.
    ///
    /// - Note: This is unrelated to the ten-minute window the server applies to a
    ///   sealed result's own timestamp, despite the matching duration. Each touch
    ///   mints a new identification, so the payload it sends is seconds old however
    ///   long this interval is.
    private static let keepAliveInterval: TimeInterval = 10 * 60

    /// A payment must not be held up indefinitely by the fingerprinting SDK.
    private static let visitorIdTimeout: TimeInterval = 5

    private let storage: SessionStorage

    private var inFlight: [String: Task<SessionId, Error>] = [:]

    /// The account whose session the keep-alive should re-touch. `nil` means no account is known
    /// yet, so the pre-account warm-up session is the live one.
    ///
    /// This is what stops the keep-alive from `POST`ing a fresh orphan over an adopted session:
    /// once an account is known, refreshes go out as an update and preserve the account binding.
    private var activeAccountId: String?

    /// The running keep-alive. Held so foreground/background transitions can restart and cancel it.
    private var keepAlive: Task<Void, Never>?

    /// Creates a session manager backed by the given storage.
    ///
    /// - Parameter storage: Where session identifiers are persisted. Defaults to `UserDefaults`.
    public init(storage: SessionStorage = UserDefaultsSessionStorage()) {
        self.storage = storage
    }

    /// Returns a session for `accountId` that is fresh enough to back a payment, creating or
    /// refreshing one if necessary.
    ///
    /// Idempotent, and coalesces concurrent callers onto a single round trip.
    ///
    /// - Parameter accountId: The Frame account the payment belongs to.
    /// - Returns: The session identifier to send with the payment.
    /// - Throws: ``SessionManagerError`` if no session could be established.
    @discardableResult
    public func ensureSession(accountId: String) async throws -> SessionId {
        // From here on the keep-alive refreshes this account's session rather than the
        // pre-account one.
        activeAccountId = accountId
        startKeepAlive()

        if let existing = storage.get(accountId: accountId), isFresh(accountId: accountId) {
            return existing
        }

        if let running = inFlight[accountId] {
            return try await running.value
        }

        let task = Task<SessionId, Error> {
            try await establishSession(accountId: accountId)
        }
        inFlight[accountId] = task

        defer { inFlight[accountId] = nil }
        return try await task.value
    }

    /// Establishes a session at SDK start-up, before an account is known.
    ///
    /// The server fetches a new session's device event asynchronously, so starting early gives that
    /// event time to land before checkout. ``ensureSession(accountId:)`` then adopts the session onto
    /// the account, and is left to retry and report any failure here.
    public static func initializeSession() async {
        try? await shared.warmUp()
        await shared.startKeepAlive()
    }

    /// Brings the pre-account session into the freshness window, creating one only when none exists.
    ///
    /// The three cases are distinct and the difference matters:
    /// - **Fresh** — nothing to do.
    /// - **Stale** — refreshed *in place*, keeping the same session ID so the new device event
    ///   accumulates against the session the adoption path will look for. Replacing it with a new
    ///   session here would reintroduce the event-landing race that creating early exists to avoid.
    /// - **Absent** — created.
    ///
    /// See ``initializeSession()``.
    func warmUp() async throws {
        if storage.get(accountId: nil) != nil, isFresh(accountId: nil) { return }

        if let stale = storage.get(accountId: nil) {
            let refreshed = try await refreshSession(stale, accountId: nil)
            store(refreshed, accountId: nil)
            return
        }

        let session = try await createSession(accountId: nil)
        store(session, accountId: nil)
    }

    /// Re-touches the live session and restarts the keep-alive after the app returns to the
    /// foreground.
    ///
    /// Backgrounding is the most common way a session goes stale — timers do not fire while
    /// suspended, so the window can close with nothing to notice.
    public func resume() async {
        await touchActiveSession()
        startKeepAlive()
    }

    /// Stops the keep-alive while the app is backgrounded, so it neither burns cycles nor fires
    /// requests that would be suspended mid-flight.
    public func pause() {
        keepAlive?.cancel()
        keepAlive = nil
    }

    /// Records a device event when the merchant presents one of the SDK's entry-point views —
    /// onboarding, checkout, or a standalone payment element.
    ///
    /// Mirrors the web SDK, which writes the session once per page load: an update when one is stored
    /// and a create when none is. A native app has no page loads, so presenting one of these views is
    /// the closest equivalent — it is the point where the user has committed to a flow that risk
    /// checks will score.
    ///
    /// Deliberately unconditional rather than gated on ``isFresh(accountId:)``: the freshness window is
    /// an SDK-side estimate of the server's, and entering a flow is exactly when it is worth spending
    /// a request to be certain the session carries a recent event. Failures are ignored — this is
    /// opportunistic, and the payment path still calls ``ensureSession(accountId:)``.
    ///
    /// Fire-and-forget from a view's `.task`/`.onAppear`; it never blocks presentation.
    public func refreshOnFlowEntry(accountId: String? = nil) async {
        guard let stored = storage.get(accountId: accountId) else {
            if let created = try? await createSession(accountId: accountId) {
                store(created, accountId: accountId)
            }
            return
        }

        if let refreshed = try? await refreshSession(stored, accountId: accountId) {
            store(refreshed, accountId: accountId)
        }
    }

    // MARK: - Private

    /// Starts the periodic refresh of whichever session is currently live, if it is not already
    /// running.
    ///
    /// Idempotent by design: this is called from every ``ensureSession(accountId:)``, and cancelling
    /// and recreating the task each time would restart the interval, so a user retrying checkout
    /// could push the next refresh out indefinitely. The tick reads ``activeAccountId`` when it
    /// fires, so an already-running timer picks up a newly adopted account without a restart.
    private func startKeepAlive() {
        guard keepAlive == nil else { return }

        keepAlive = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Self.keepAliveInterval * 1_000_000_000))
                if Task.isCancelled { return }
                guard let self else { return }
                await self.touchActiveSession()
            }
        }
    }

    /// Refreshes the live session: the adopted account session when one is known, otherwise the
    /// pre-account warm-up session.
    ///
    /// Failures are swallowed deliberately — this runs in the background, and a missed keep-alive is
    /// recovered by ``ensureSession(accountId:)`` on the payment path.
    private func touchActiveSession() async {
        guard let accountId = activeAccountId else {
            try? await warmUp()
            return
        }

        // Join an in-flight establish rather than issuing a competing one — a keep-alive tick can
        // land while checkout is already establishing the same session.
        if let running = inFlight[accountId] {
            _ = try? await running.value
            return
        }

        let task = Task<SessionId, Error> {
            try await establishSession(accountId: accountId)
        }
        inFlight[accountId] = task
        defer { inFlight[accountId] = nil }
        _ = try? await task.value
    }

    private func isFresh(accountId: String?) -> Bool {
        guard let last = storage.lastRefresh(accountId: accountId) else { return false }
        return Date().timeIntervalSince(last) < Self.refreshInterval
    }

    private func store(_ session: SessionId, accountId: String?) {
        storage.set(session, accountId: accountId)
        storage.setLastRefresh(Date(), accountId: accountId)
    }

    private func establishSession(accountId: String) async throws -> SessionId {
        if let existing = storage.get(accountId: accountId) {
            let refreshed = try await refreshSession(existing, accountId: accountId)
            store(refreshed, accountId: accountId)
            return refreshed
        }

        if let legacy = storage.get(accountId: nil) {
            let adopted = try await refreshSession(legacy, accountId: accountId)
            store(adopted, accountId: accountId)
            // Leaving the legacy slot readable would let the next account on this device adopt the
            // same session.
            storage.clear(accountId: nil)
            return adopted
        }

        let created = try await createSession(accountId: accountId)
        store(created, accountId: accountId)
        return created
    }

    private func createSession(accountId: String?) async throws -> SessionId {
        let body = SessionRequestBody(identification: try await identification(), accountId: accountId)
        return try await perform(endpoint: SonarSessionEndpoints.create, body: body)
    }

    /// Updates an existing session, associating it with `accountId` and recording a new device event
    /// server-side — the latter is what returns the session to the freshness window.
    ///
    /// A `nil` `accountId` refreshes the pre-account session in place, keeping the same session ID so
    /// the device event accumulates against it rather than against a fresh orphan.
    private func refreshSession(_ session: SessionId, accountId: String?) async throws -> SessionId {
        let body = SessionRequestBody(identification: try await identification(), accountId: accountId)
        do {
            return try await perform(endpoint: SonarSessionEndpoints.update(id: session), body: body)
        } catch SessionManagerError.requestFailed {
            // The server no longer recognises this session, so replace it rather than fail the payment.
            storage.clear(accountId: accountId)
            return try await createSession(accountId: accountId)
        }
    }

    private func perform(endpoint: SonarSessionEndpoints, body: SessionRequestBody) async throws -> SessionId {
        let encoded = try FrameNetworking.shared.jsonEncoder.encode(body)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: encoded, auth: .publishable)

        if let error { throw SessionManagerError.requestFailed(error) }
        guard let data else { throw SessionManagerError.requestFailed(.noData) }

        do {
            return try FrameNetworking.shared.jsonDecoder.decode(SessionResponse.self, from: data).sonarSessionId
        } catch {
            throw SessionManagerError.requestFailed(.decodingFailed)
        }
    }

    /// Mints a fresh Fingerprint identification for a single request.
    ///
    /// Called again for every create, refresh and keep-alive touch rather than
    /// held: a sealed result carries its own timestamp and the server rejects one
    /// stamped more than ten minutes from now in either direction, so a reused
    /// payload is a rejected payload — sharpest on a device that suspends and
    /// resumes hours later.
    ///
    /// An empty visitor id is not a failure on its own. An activated Fingerprint
    /// environment withholds it by design and identifies by sealed result instead,
    /// so this only throws when neither is present.
    private func identification() async throws -> FingerprintIdentification {
        guard let identification = try? await FingerprintManager.identify(timeout: Self.visitorIdTimeout),
              identification.isUsable else {
            throw SessionManagerError.missingVisitorId
        }
        return identification
    }
}