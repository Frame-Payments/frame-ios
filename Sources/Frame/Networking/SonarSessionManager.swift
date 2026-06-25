import Foundation

// MARK: - SessionManager

/// Manages the lifecycle of a Sonar fraud-detection session, including creation, updating, and local persistence.
///
/// `SessionManager` coordinates with `FingerprintManager` to obtain a device visitor ID and then
/// creates or refreshes a Sonar session via the Frame networking layer. The resulting session ID is
/// persisted in `UserDefaults` so that subsequent launches can resume an existing session instead of
/// creating a new one.
public final class SessionManager {
    private let visitorId: String
    private let storage: SessionStorage = UserDefaultsSessionStorage()

    /// Creates a `SessionManager` bound to the given Fingerprint visitor identifier.
    ///
    /// - Parameter visitorId: The Fingerprint visitor ID used to associate this session with a device.
    public init(visitorId: String) {
        self.visitorId = visitorId
    }

    /// Creates a new Sonar session if none is stored, or updates the existing session.
    public func initialize() async {
        if storage.get() == nil {
            await createSession()
        } else {
            await updateSession()
        }
    }

    private func createSession() async {
        do {
            let endpoint = SonarSessionEndpoints.create
            let body = try FrameNetworking.shared.jsonEncoder.encode(SessionRequestBody(fingerprintVisitorId: visitorId))
            let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body, auth: .publishable)
            
            if let error {
                throw error
            }
            
            guard let data else {
                throw NetworkingError.noData
            }
            
            let response = try FrameNetworking.shared.jsonDecoder.decode(SessionResponse.self, from: data)
            setSession(response.sonarSessionId)
        } catch {
            print("Failed to create charge session: \(error)")
        }
    }

    private func updateSession() async {
        guard let current = storage.get() else {
            await createSession()
            return
        }

        do {
            let endpoint = SonarSessionEndpoints.update(id: current)
            let body = try FrameNetworking.shared.jsonEncoder.encode(SessionRequestBody(fingerprintVisitorId: visitorId))
            let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body, auth: .publishable)
            
            if let error {
                throw error
            }
            
            guard let data else {
                throw NetworkingError.noData
            }
            
            let response = try FrameNetworking.shared.jsonDecoder.decode(SessionResponse.self, from: data)
            setSession(response.sonarSessionId)
        } catch {
            print("Failed to update session, creating new one: \(error)")
            clearStoredSessionId()
            await createSession()
            return
        }
    }

    private func setSession(_ sessionId: SessionId) {
        storage.set(sessionId)
    }
    
    private func clearStoredSessionId() {
        storage.clear()
    }
    
    /// Convenience method that fetches the Fingerprint visitor ID and initialises a `SessionManager` in one step.
    ///
    /// Call this from your app's startup path to ensure a valid Sonar session exists before processing payments.
    public static func initializeSession() async {
        do {
            guard let visitorId = try await FingerprintManager.getVisitorId() else { return }
            let manager = SessionManager(visitorId: visitorId)
            await manager.initialize()
        } catch {
            print("Failed to initialize session with Fingerprint visitorId: \(error)")
        }
    }
}
