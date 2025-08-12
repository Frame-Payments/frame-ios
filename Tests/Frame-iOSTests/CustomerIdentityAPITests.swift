//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import XCTest
@testable import Frame_iOS

final class CustomerIdentityAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil,
                                      response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/customer_identity_verifications")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil),
                                      error: nil)
    
    func testCreateCustomerIdentity() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let billingAddress = FrameObjects.BillingAddress(postalCode: "11111")
        let request = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: "Tester",
                                                                            lastName: "Testing",
                                                                            dateOfBirth: "08/08/1998",
                                                                            email: "testing@gmail.com",
                                                                            phoneNumber: "999-999-9999",
                                                                            ssn: "XXX-XXX-XXXX",
                                                                            address: billingAddress)
        
        let createdCustomerIdentity = try? await CustomerIdentityAPI.createCustomerIdentity(request: request)
        XCTAssertNil(createdCustomerIdentity)
        
        let customerIdentity = FrameObjects.CustomerIdentity(id: "1",
                                                             status: .pending,
                                                             verificationURL: "",
                                                             object: "",
                                                             created: 000000,
                                                             updated: 000000,
                                                             pending: 000000,
                                                             verified: 000000,
                                                             failed: 000000)
        
        do {
            session.data = try JSONEncoder().encode(customerIdentity)
            let createdCustomerIdentityTwo = try await CustomerIdentityAPI.createCustomerIdentity(request: request)
            XCTAssertNotNil(createdCustomerIdentityTwo)
            XCTAssertEqual(createdCustomerIdentityTwo?.status, customerIdentity.status)
            XCTAssertEqual(createdCustomerIdentityTwo?.id, customerIdentity.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomerIdentity() async {
        FrameNetworking.shared.asyncURLSession = session
        let receivedCustomerIdentity = try? await CustomerIdentityAPI.getCustomerIdentityWith(customerIdentityId: "")
        XCTAssertNil(receivedCustomerIdentity)
        
        let receivedCustomerIdentityTwo = try? await CustomerIdentityAPI.getCustomerIdentityWith(customerIdentityId: "123")
        XCTAssertNil(receivedCustomerIdentityTwo)
        
        let customerIdentity = FrameObjects.CustomerIdentity(id: "1234",
                                                             status: .pending,
                                                             verificationURL: "",
                                                             object: "",
                                                             created: 000000,
                                                             updated: 000000,
                                                             pending: 000000,
                                                             verified: 000000,
                                                             failed: 000000)
        
        do {
            session.data = try JSONEncoder().encode(customerIdentity)
            let receivedCustomerIdentityThree = try await CustomerIdentityAPI.getCustomerIdentityWith(customerIdentityId: "1234")
            XCTAssertNotNil(receivedCustomerIdentityThree)
            XCTAssertEqual(receivedCustomerIdentityThree?.id, customerIdentity.id)
            XCTAssertEqual(receivedCustomerIdentityThree?.status, customerIdentity.status)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
