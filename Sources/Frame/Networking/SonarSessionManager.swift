import Foundation

// MARK: - SessionManager

public final class SessionManager {
    private let visitorId: String
    private let storage: SessionStorage

    /// - Parameters:
    ///   - visitorId: fingerprint visitor id
    public init(
        visitorId: String,
        storage: SessionStorage = UserDefaultsSessionStorage()
    ) {
        self.visitorId = visitorId
        self.storage = storage
    }

    /// Mirrors TS `initialize()`:
    /// - if no session id, create
    /// - else update
    @discardableResult
    public func initialize() async throws -> SessionId {
        if storage.get() == nil {
            return try await createSession()
        }
        return try await updateSession()
    }

    private func createSession() async throws -> SessionId {
        do {
            let endpoint = SonarSessionEndpoints.create
            let body = try FrameNetworking.shared.jsonEncoder.encode(SessionRequestBody(fingerprint_visitor_id: visitorId))
            let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body)
            
            if let error {
                throw error
            }
            
            guard let data else {
                throw NetworkingError.noData
            }
            
            let response = try FrameNetworking.shared.jsonDecoder.decode(SessionResponse.self, from: data)
            setSession(response.sonar_session_id)
            return response.sonar_session_id
        } catch {
            print("Failed to create charge session: \(error)")
            throw error
        }
    }

    private func updateSession() async throws -> SessionId {
        guard let current = storage.get() else {
            return try await createSession()
        }

        do {
            let endpoint = SonarSessionEndpoints.update(id: current)
            let body = try FrameNetworking.shared.jsonEncoder.encode(SessionRequestBody(fingerprint_visitor_id: visitorId))
            let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body)
            
            if let error {
                throw error
            }
            
            guard let data else {
                throw NetworkingError.noData
            }
            
            let response = try FrameNetworking.shared.jsonDecoder.decode(SessionResponse.self, from: data)
            setSession(response.sonar_session_id)
            return response.sonar_session_id
        } catch {
            print("Failed to update session, creating new one: \(error)")
            clearStoredSessionId()
            return try await createSession()
        }
    }

    private func setSession(_ sessionId: SessionId) {
        storage.set(sessionId)
    }
    
    private func clearStoredSessionId() {
        storage.clear()
    }
    
    public static func initializeSession() async {
        // GET FINGER PRINT ID FIRST
        let manager = SessionManager(visitorId: "", storage: UserDefaultsSessionStorage())
        do {
            try await manager.initialize()
        } catch let error {
            print(error)
        }
    }
}
