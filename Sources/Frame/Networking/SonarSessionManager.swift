import Foundation

// MARK: - SessionManagerError

/// Failures raised while establishing a Sonar fraud-detection session.
public enum SessionManagerError: Error, Equatable {
    /// Fingerprint could not produce a visitor ID, so no session can be created.
    ///
    /// Without a visitor ID the server has no device to attach the session to, and any payment
    /// made against it is rejected by risk checks.
    case missingVisitorId

    /// The session create or update request failed.
    case requestFailed(NetworkingError)
}

// MARK: - SessionManager

/// Manages the lifecycle of a Sonar fraud-detection session, including creation, refresh, and
/// local persistence.
///
/// A Sonar session is what lets the server run risk and geo-compliance checks against a payment.
/// The server resolves a charge's session *through the Frame account*, so a session is only usable
/// once it has been associated with one — a session created without an account is invisible to
/// those checks and the payment is rejected with `sonar_session_required`.
///
/// Sessions are therefore persisted per account, and are refreshed periodically: the server only
/// accepts a session whose most recent device event is recent, so a session left untouched for long
/// enough goes stale and stops backing payments.
///
/// Call ``ensureSession(accountId:)`` before taking a payment and await the result; it is idempotent
/// and coalesces concurrent callers onto a single network round trip.
public actor SessionManager {
    /// The shared session manager used by the SDK.
    public static let shared = SessionManager()

    /// How long a stored session is trusted before it is refreshed.
    ///
    /// The server rejects sessions whose latest device event has aged out, so this sits well inside
    /// that window: refreshing early is cheap, while being even slightly late fails the payment.
    private static let refreshInterval: TimeInterval = 15 * 60

    /// Cap on how long the SDK waits for Fingerprint to identify the device. A payment must not be
    /// held up indefinitely by the fingerprinting SDK.
    private static let visitorIdTimeout: TimeInterval = 5

    private let storage: SessionStorage

    /// In-flight work, keyed by account, so concurrent callers (e.g. a double-tapped Pay button)
    /// share one round trip instead of racing to mint duplicate sessions.
    private var inFlight: [String: Task<SessionId, Error>] = [:]

    /// Creates a session manager backed by the given storage.
    ///
    /// - Parameter storage: Where session identifiers are persisted. Defaults to `UserDefaults`.
    public init(storage: SessionStorage = UserDefaultsSessionStorage()) {
        self.storage = storage
    }

    /// Returns a session for `accountId` that is fresh enough to back a payment, creating or
    /// refreshing one if necessary.
    ///
    /// Awaiting this before a payment guarantees the session exists and is associated with the
    /// account — otherwise the payment races SDK start-up and can be rejected with
    /// `sonar_session_required`.
    ///
    /// - Parameter accountId: The Frame account the payment belongs to.
    /// - Returns: The session identifier to send with the payment.
    /// - Throws: ``SessionManagerError`` if no session could be established.
    @discardableResult
    public func ensureSession(accountId: String) async throws -> SessionId {
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
    /// This is a head start, not a guarantee: the server fetches the device event for a new session
    /// asynchronously, so creating the session early gives that event time to land before checkout.
    /// The session is adopted by the account on the first ``ensureSession(accountId:)`` call.
    ///
    /// Failures are non-fatal and left to ``ensureSession(accountId:)`` to retry and report, so this
    /// never throws into the SDK's start-up path.
    public static func initializeSession() async {
        try? await shared.warmUp()
    }

    /// Creates a pre-account session if none is stored. See ``initializeSession()``.
    func warmUp() async throws {
        guard storage.get(accountId: nil) == nil else { return }
        let session = try await createSession(accountId: nil)
        store(session, accountId: nil)
    }

    // MARK: - Private

    private func isFresh(accountId: String?) -> Bool {
        guard let last = storage.lastRefresh(accountId: accountId) else { return false }
        return Date().timeIntervalSince(last) < Self.refreshInterval
    }

    private func store(_ session: SessionId, accountId: String?) {
        storage.set(session, accountId: accountId)
        storage.setLastRefresh(Date(), accountId: accountId)
    }

    /// Produces a fresh, account-associated session, reusing whatever is already stored.
    ///
    /// Three cases, in order of preference:
    /// 1. A session already exists for the account — refresh it so it is inside the server's
    ///    freshness window again.
    /// 2. A pre-account session exists — adopt it onto this account and retire the legacy slot, so
    ///    it can never be adopted a second time by a different account.
    /// 3. Nothing stored — create one against the account.
    private func establishSession(accountId: String) async throws -> SessionId {
        if let existing = storage.get(accountId: accountId) {
            let refreshed = try await refreshSession(existing, accountId: accountId)
            store(refreshed, accountId: accountId)
            return refreshed
        }

        if let legacy = storage.get(accountId: nil) {
            let adopted = try await refreshSession(legacy, accountId: accountId)
            store(adopted, accountId: accountId)
            // Retire the legacy slot: it now belongs to this account, and leaving it readable would
            // let the next account on this device adopt the same session.
            storage.clear(accountId: nil)
            return adopted
        }

        let created = try await createSession(accountId: accountId)
        store(created, accountId: accountId)
        return created
    }

    private func createSession(accountId: String?) async throws -> SessionId {
        let body = SessionRequestBody(fingerprintVisitorId: try await visitorId(), accountId: accountId)
        return try await perform(endpoint: SonarSessionEndpoints.create, body: body)
    }

    /// Updates an existing session, which both associates it with `accountId` and records a new
    /// device event server-side — the latter is what returns the session to the server's freshness
    /// window.
    ///
    /// A session the server no longer recognises (expired, or created under different credentials)
    /// is replaced rather than propagated as an error.
    private func refreshSession(_ session: SessionId, accountId: String) async throws -> SessionId {
        let body = SessionRequestBody(fingerprintVisitorId: try await visitorId(), accountId: accountId)
        do {
            return try await perform(endpoint: SonarSessionEndpoints.update(id: session), body: body)
        } catch SessionManagerError.requestFailed {
            storage.clear(accountId: accountId)
            return try await createSession(accountId: accountId)
        }
    }

    private func perform(endpoint: SonarSessionEndpoints, body: SessionRequestBody) async throws -> SessionId {
        let encoded = try FrameNetworking.shared.jsonEncoder.encode(body)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: encoded)

        if let error { throw SessionManagerError.requestFailed(error) }
        guard let data else { throw SessionManagerError.requestFailed(.noData) }

        do {
            return try FrameNetworking.shared.jsonDecoder.decode(SessionResponse.self, from: data).sonarSessionId
        } catch {
            throw SessionManagerError.requestFailed(.decodingFailed)
        }
    }

    private func visitorId() async throws -> String {
        guard let id = try? await FingerprintManager.getVisitorId(timeout: Self.visitorIdTimeout), !id.isEmpty else {
            throw SessionManagerError.missingVisitorId
        }
        return id
    }
}
