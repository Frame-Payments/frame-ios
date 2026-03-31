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
                name: FrameObjects.AccountNameInfo(firstName: "John", middleName: nil, lastName: "Doe", suffix: nil),
                email: "john@test.com",
                phone: phone,
                address: nil,
                birthdate: nil,
                ssn: nil
            )
        )
        let request = AccountRequest.CreateAccountRequest(
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
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
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
        
        let profile = AccountRequest.UpdateAccountProfile(
            business: nil,
            individual: AccountRequest.UpdateIndividualAccount(
                name: FrameObjects.AccountNameInfo(firstName: "John", middleName: nil, lastName: "Doe", suffix: nil),
                email: "john@test.com",
                phoneNumber: "1234567890",
                phoneCountryCode: "1",
                address: nil,
                birthdate: nil,
                ssn: nil
            )
        )
        let request = AccountRequest.UpdateAccountRequest(
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
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
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
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
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
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
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
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
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
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
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

    func testSearchAccounts() async {
        FrameNetworking.shared.asyncURLSession = session

        let emptyResult = try? await AccountsAPI.searchAccounts(email: "").0
        XCTAssertNil(emptyResult)

        let noDataResult = try? await AccountsAPI.searchAccounts(email: "john@test.com").0
        XCTAssertNil(noDataResult)

        let account = FrameObjects.Account(
            id: "acc_123",
            object: "account",
            accountType: .individual,
            accountStatus: .active,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
            livemode: false
        )

        do {
            let response = AccountResponses.ListAccountsResponse(meta: nil, data: [account])
            session.data = try FrameNetworking.shared.jsonEncoder.encode(response)
            let (searchResult, _) = try await AccountsAPI.searchAccounts(email: "john@test.com")
            XCTAssertNotNil(searchResult)
            XCTAssertEqual(searchResult?.data?[0].id, account.id)
            XCTAssertEqual(searchResult?.data?[0].accountStatus, .active)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }

    func testGetPaymentMethodsForAccount() async {
        FrameNetworking.shared.asyncURLSession = session

        let emptyResult = try? await AccountsAPI.getPaymentMethodsForAccount(accountId: "").0
        XCTAssertNil(emptyResult)

        let noDataResult = try? await AccountsAPI.getPaymentMethodsForAccount(accountId: "acc_123").0
        XCTAssertNil(noDataResult)

        let paymentMethodOne = FrameObjects.PaymentMethod(id: "pm_1", customerId: "acc_123", type: .card, object: "", created: 0, updated: 0, livemode: false, status: .active)
        let paymentMethodTwo = FrameObjects.PaymentMethod(id: "pm_2", customerId: "acc_123", type: .ach, object: "", created: 0, updated: 0, livemode: false, status: .active)

        do {
            let response = PaymentMethodResponses.ListPaymentMethodsResponse(meta: nil, data: [paymentMethodOne, paymentMethodTwo])
            session.data = try FrameNetworking.shared.jsonEncoder.encode(response)
            let (methodsResult, _) = try await AccountsAPI.getPaymentMethodsForAccount(accountId: "acc_123")
            XCTAssertNotNil(methodsResult)
            XCTAssertEqual(methodsResult?.data?[0].id, paymentMethodOne.id)
            XCTAssertEqual(methodsResult?.data?[1].id, paymentMethodTwo.id)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }

    func testRestrictAccount() async {
        FrameNetworking.shared.asyncURLSession = session

        let emptyResult = try? await AccountsAPI.restrictAccount(accountId: "").0
        XCTAssertNil(emptyResult)

        let noDataResult = try? await AccountsAPI.restrictAccount(accountId: "acc_123").0
        XCTAssertNil(noDataResult)

        let account = FrameObjects.Account(
            id: "acc_123",
            object: "account",
            accountType: .individual,
            accountStatus: .restricted,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
            livemode: false
        )

        do {
            session.data = try FrameNetworking.shared.jsonEncoder.encode(account)
            let (restrictedAccount, _) = try await AccountsAPI.restrictAccount(accountId: "acc_123")
            XCTAssertNotNil(restrictedAccount)
            XCTAssertEqual(restrictedAccount?.id, account.id)
            XCTAssertEqual(restrictedAccount?.accountStatus, .restricted)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }

    func testUnrestrictAccount() async {
        FrameNetworking.shared.asyncURLSession = session

        let emptyResult = try? await AccountsAPI.unrestrictAccount(accountId: "").0
        XCTAssertNil(emptyResult)

        let noDataResult = try? await AccountsAPI.unrestrictAccount(accountId: "acc_123").0
        XCTAssertNil(noDataResult)

        let account = FrameObjects.Account(
            id: "acc_123",
            object: "account",
            accountType: .individual,
            accountStatus: .active,
            externalId: nil,
            metadata: nil,
            profile: nil,
            capabilities: nil,
            steps: nil,
            created: 1234567890,
            updated: 1234567890,
            livemode: false
        )

        do {
            session.data = try FrameNetworking.shared.jsonEncoder.encode(account)
            let (unrestrictedAccount, _) = try await AccountsAPI.unrestrictAccount(accountId: "acc_123")
            XCTAssertNotNil(unrestrictedAccount)
            XCTAssertEqual(unrestrictedAccount?.id, account.id)
            XCTAssertEqual(unrestrictedAccount?.accountStatus, .active)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
}
