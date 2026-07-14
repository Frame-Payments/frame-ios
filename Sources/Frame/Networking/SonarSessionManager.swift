import Foundation

// MARK: - SessionManagerError

/// Failures raised while establishing a Sonar fraud-detection session.
public enum SessionManagerError: Error, Equatable {
    /// Fingerprint could not identify the device, so no session can be created.
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

    /// A payment must not be held up indefinitely by the fingerprinting SDK.
    private static let visitorIdTimeout: TimeInterval = 5

    private let storage: SessionStorage

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
    /// Idempotent, and coalesces concurrent callers onto a single round trip.
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
    /// The server fetches a new session's device event asynchronously, so starting early gives that
    /// event time to land before checkout. ``ensureSession(accountId:)`` then adopts the session onto
    /// the account, and is left to retry and report any failure here.
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
        let body = SessionRequestBody(fingerprintVisitorId: try await visitorId(), accountId: accountId)
        return try await perform(endpoint: SonarSessionEndpoints.create, body: body)
    }

    /// Updates an existing session, associating it with `accountId` and recording a new device event
    /// server-side — the latter is what returns the session to the freshness window.
    private func refreshSession(_ session: SessionId, accountId: String) async throws -> SessionId {
        let body = SessionRequestBody(fingerprintVisitorId: try await visitorId(), accountId: accountId)
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
