//
//  SiftUserIdTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

final class SiftUserIdTests: XCTestCase {
    override func setUp() {
        super.setUp()
        SiftManager.currentUserId = nil
    }

    func testAccountDecodesSiftUserId() throws {
        let json = """
        {
          "id": "acc_123",
          "object": "account",
          "type": "individual",
          "status": "active",
          "sift_user_id": "idt_456",
          "created": 1,
          "updated": 1,
          "livemode": false
        }
        """.data(using: .utf8)!

        let account = try FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: json)

        XCTAssertEqual(account.id, "acc_123")
        XCTAssertEqual(account.siftUserId, "idt_456")
        XCTAssertEqual(account.siftAttributionId, "idt_456")
    }

    func testSiftAttributionIdFallsBackToAccountId() throws {
        let json = """
        {
          "id": "acc_123",
          "object": "account",
          "type": "individual",
          "status": "active",
          "created": 1,
          "updated": 1,
          "livemode": false
        }
        """.data(using: .utf8)!

        let account = try FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: json)

        XCTAssertNil(account.siftUserId)
        XCTAssertEqual(account.siftAttributionId, "acc_123")
    }

    func testCollectLoginEventUsesSiftUserIdAndAllowsOverwrite() {
        SiftManager.collectLoginEvent(userId: "acc_old", email: "a@example.com")
        XCTAssertEqual(SiftManager.currentUserId, "acc_old")

        SiftManager.collectLoginEvent(userId: "idt_new", email: "a@example.com")
        XCTAssertEqual(SiftManager.currentUserId, "idt_new")
    }

    func testCollectLoginEventOverwriteFalseDoesNotReplace() {
        SiftManager.collectLoginEvent(userId: "idt_keep", email: "a@example.com")
        SiftManager.collectLoginEvent(userId: "acc_fallback", email: "", overwrite: false)
        XCTAssertEqual(SiftManager.currentUserId, "idt_keep")
    }

    func testCreateAccountPassesSiftUserIdToSiftManager() async throws {
        let session = MockURLAsyncSession(
            data: """
            {
              "id": "acc_123",
              "object": "account",
              "type": "individual",
              "status": "pending",
              "sift_user_id": "idt_789",
              "created": 1,
              "updated": 1,
              "livemode": false
            }
            """.data(using: .utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://api.framepayments.com/v1/accounts")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            ),
            error: nil
        )
        FrameNetworking.shared.asyncURLSession = session

        let request = AccountRequest.CreateAccountRequest(
            accountType: .individual,
            externalId: nil,
            termsOfService: nil,
            metadata: nil,
            profile: nil
        )
        let (account, _) = try await AccountsAPI.createAccount(request: request, forTesting: false)

        XCTAssertEqual(account?.siftUserId, "idt_789")
        XCTAssertEqual(SiftManager.currentUserId, "idt_789")
    }
}
