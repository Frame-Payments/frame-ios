import Foundation

// MARK: - SessionManager

public final class SessionManager {
    private let visitorId: String
    private let storage: SessionStorage = UserDefaultsSessionStorage()

    /// - Parameters:
    ///   - visitorId: fingerprint visitor id
    public init(visitorId: String) {
        self.visitorId = visitorId
    }

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
            let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body)
            
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
            let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body)
            
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
