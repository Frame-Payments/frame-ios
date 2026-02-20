//
//  AccountsAPITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import XCTest
@testable import Frame

final class AccountsAPITests: XCTestCase {
    let session = MockURLAsyncSession(
        data: nil,
        response: HTTPURLResponse(
            url: URL(string: "https://api.framepayments.com/v1/accounts")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ),
        error: nil
    )
    
    func testCreateAccount() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let phone = FrameObjects.AccountPhoneNumber(number: "1234567890", countryCode: "1")
        let profile = AccountRequest.CreateAccountProfile(
            business: nil,
            individual: AccountRequest.CreateIndividualAccount(
                name: AccountRequest.CreateAccountInfo(firstName: "John", middleName: nil, lastName: "Doe", suffix: nil),
                email: "john@test.com",
                phone: phone,
                address: nil,
                dob: nil,
                ssn: nil
            )
        )
        var request = AccountRequest.CreateAccountRequest(
            accountType: .individual,
            externalId: nil,
            termsOfService: nil,
            metadata: nil,
            profile: profile
        )
        XCTAssertNotNil(request.profile)
        XCTAssertEqual(request.accountType, .individual)
        
        let createdAccount = try? await AccountsAPI.createAccount(request: request, forTesting: true).0
        XCTAssertNil(createdAccount)
        
        let account = FrameObjects.Account(
            id: "acc_123",
            object: "account",
            accountType: .individual,
            accountStatus: .pending,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890,
            livemode: false
        )
        
        do {
            session.data = try FrameNetworking.shared.jsonEncoder.encode(account)
            let (createdAccountTwo, _) = try await AccountsAPI.createAccount(request: request, forTesting: true)
            XCTAssertNotNil(createdAccountTwo)
            XCTAssertEqual(createdAccountTwo?.id, account.id)
            XCTAssertEqual(createdAccountTwo?.accountStatus, .pending)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
    
    func testUpdateAccountWith() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let phone = FrameObjects.AccountPhoneNumber(number: "1234567890", countryCode: "1")
        let profile = AccountRequest.CreateAccountProfile(
            business: nil,
            individual: AccountRequest.CreateIndividualAccount(
                name: AccountRequest.CreateAccountInfo(firstName: "John", middleName: nil, lastName: "Doe", suffix: nil),
                email: "john@test.com",
                phone: phone,
                address: nil,
                dob: nil,
                ssn: nil
            )
        )
        var request = AccountRequest.UpdateAccountRequest(
            accountType: .individual,
            externalId: nil,
            termsOfService: nil,
            metadata: nil,
            profile: profile
        )
        
        let updatedAccount = try? await AccountsAPI.updateAccountWith(accountId: "", request: request).0
        XCTAssertNil(updatedAccount)
        
        let updatedAccountTwo = try? await AccountsAPI.updateAccountWith(accountId: "acc_123", request: request).0
        XCTAssertNil(updatedAccountTwo)
        
        let account = FrameObjects.Account(
            id: "acc_123",
            object: "account",
            accountType: .individual,
            accountStatus: .active,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890,
            livemode: false
        )
        
        do {
            session.data = try FrameNetworking.shared.jsonEncoder.encode(account)
            let (updatedAccountThree, _) = try await AccountsAPI.updateAccountWith(accountId: "acc_123", request: request)
            XCTAssertNotNil(updatedAccountThree)
            XCTAssertEqual(updatedAccountThree?.id, account.id)
            XCTAssertEqual(updatedAccountThree?.accountStatus, .active)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
    
    func testGetAccounts() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let accounts = try? await AccountsAPI.getAccounts(status: nil, type: nil, externalId: nil, includeDisabled: false).0
        XCTAssertNil(accounts)
        
        let accountOne = FrameObjects.Account(
            id: "acc_1",
            object: "account",
            accountType: .individual,
            accountStatus: .active,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890,
            livemode: false
        )
        let accountTwo = FrameObjects.Account(
            id: "acc_2",
            object: "account",
            accountType: .business,
            accountStatus: .pending,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890,
            livemode: false
        )
        
        do {
            let response = AccountResponses.ListAccountsResponse(meta: nil, data: [accountOne, accountTwo])
            session.data = try FrameNetworking.shared.jsonEncoder.encode(response)
            let (accountsResponse, _) = try await AccountsAPI.getAccounts(status: nil, type: nil, externalId: nil, includeDisabled: false)
            XCTAssertNotNil(accountsResponse)
            XCTAssertEqual(accountsResponse?.data?[0].id, accountOne.id)
            XCTAssertEqual(accountsResponse?.data?[1].id, accountTwo.id)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
    
    func testGetAccountWith() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let receivedAccount = try? await AccountsAPI.getAccountWith(accountId: "", forTesting: true).0
        XCTAssertNil(receivedAccount)
        
        let receivedAccountTwo = try? await AccountsAPI.getAccountWith(accountId: "acc_123", forTesting: true).0
        XCTAssertNil(receivedAccountTwo)
        
        let account = FrameObjects.Account(
            id: "acc_123",
            object: "account",
            accountType: .individual,
            accountStatus: .active,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890,
            livemode: false
        )
        
        do {
            session.data = try FrameNetworking.shared.jsonEncoder.encode(account)
            let (receivedAccountThree, _) = try await AccountsAPI.getAccountWith(accountId: "acc_123", forTesting: true)
            XCTAssertNotNil(receivedAccountThree)
            XCTAssertEqual(receivedAccountThree?.id, account.id)
            XCTAssertEqual(receivedAccountThree?.accountStatus, .active)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
    
    func testDeleteAccountWith() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let deletedAccount = try? await AccountsAPI.deleteAccountWith(accountId: "").0
        XCTAssertNil(deletedAccount)
        
        let deletedAccountTwo = try? await AccountsAPI.deleteAccountWith(accountId: "acc_123").0
        XCTAssertNil(deletedAccountTwo)
        
        let account = FrameObjects.Account(
            id: "acc_123",
            object: "account",
            accountType: .individual,
            accountStatus: .disabled,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890,
            livemode: false
        )
        
        do {
            session.data = try FrameNetworking.shared.jsonEncoder.encode(account)
            let (deletedAccountThree, _) = try await AccountsAPI.deleteAccountWith(accountId: "acc_123")
            XCTAssertNotNil(deletedAccountThree)
            XCTAssertEqual(deletedAccountThree?.id, account.id)
            XCTAssertEqual(deletedAccountThree?.accountStatus, .disabled)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
}
