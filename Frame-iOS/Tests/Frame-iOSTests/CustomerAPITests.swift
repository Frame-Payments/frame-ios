//
//  Test.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/3/24.
//

import XCTest
@testable import Frame_iOS

final class CustomerAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/customers")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    
    func testCreateCustomer() async {
        var request = CustomerRequest.CreateCustomerRequest(name: "Tester", email: "tester@gmail.com")
        XCTAssertNotNil(request.name)
        XCTAssertNotNil(request.email)
        
        XCTAssertNil(request.description)
        request.description = "New Customer"
        XCTAssertNotNil(request.description)
        
        XCTAssertNil(request.phone)
        request.phone = "999-999-9999"
        XCTAssertNotNil(request.phone)
        
        XCTAssertNil(request.billingAddress)
        request.billingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        XCTAssertNotNil(request.billingAddress)
        
        XCTAssertNil(request.shippingAddress)
        request.shippingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        XCTAssertNotNil(request.shippingAddress)
        
        let customer = try? await CustomersAPI(mockSession: session).createCustomer(request: request)
        XCTAssertNil(customer)
        
        do {
            session.data = try JSONEncoder().encode(Frame_iOS.FrameObjects.Customer(id: "1", livemode: false, name: "Tester"))
            let customerTwo = try await CustomersAPI(mockSession: session).createCustomer(request: request)
            XCTAssertNotNil(customerTwo)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testDeleteCustomer() async {
        let customerResponse = try? await CustomersAPI(mockSession: session).deleteCustomer(customerId: "")
        XCTAssertNil(customerResponse)
        
        let customerTwoResponse = try? await CustomersAPI(mockSession: session).deleteCustomer(customerId: "123")
        XCTAssertNil(customerTwoResponse)
        
        session.data = try? JSONEncoder().encode(Frame_iOS.CustomerResponses.DeleteCustomerResponse(id: "1243", object: nil, deleted: nil))
        let customerThreeResponse = try? await CustomersAPI(mockSession: session).deleteCustomer(customerId: "1234")
        XCTAssertNotNil(customerThreeResponse)
    }
    
    func testUpdateCustomer() async {
        var request = CustomerRequest.UpdateCustomerRequest(name: "Tester")
        
        XCTAssertNil(request.email)
        request.email = "tester@gmail.com"
        XCTAssertNotNil(request.email)
        
        XCTAssertNil(request.phone)
        request.phone = "999-999-9999"
        XCTAssertNotNil(request.phone)
        
        XCTAssertNil(request.description)
        request.description = "Testing"
        XCTAssertNotNil(request.description)
        
        XCTAssertNil(request.billingAddress)
        request.billingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        XCTAssertNotNil(request.billingAddress)
        
        XCTAssertNil(request.shippingAddress)
        request.shippingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        XCTAssertNotNil(request.shippingAddress)
        
        let customer = try? await CustomersAPI(mockSession: session).updateCustomerWith(customerId: "", request: request)
        XCTAssertNil(customer)
        
        let customerTwo = try? await CustomersAPI(mockSession: session).updateCustomerWith(customerId: "123", request: request)
        XCTAssertNil(customerTwo)
        
        do {
            session.data = try JSONEncoder().encode(Frame_iOS.FrameObjects.Customer(id: "1234", livemode: false, name: "Tester"))
            let customerThree = try await CustomersAPI(mockSession: session).updateCustomerWith(customerId: "1234", request: request)
            XCTAssertNotNil(customerThree)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomers() async {
        let customers = try? await CustomersAPI(mockSession: session).getCustomers()
        XCTAssertNil(customers)
        
        do {
            let response = Frame_iOS.CustomerResponses.ListCustomersResponse(data: [Frame_iOS.FrameObjects.Customer(id: "1234", livemode: false, name: "Tester"),
                                                                                    Frame_iOS.FrameObjects.Customer(id: "12345", livemode: false, name: "Tester2")])
            
            session.data = try JSONEncoder().encode(response)
            let customersTwo = try await CustomersAPI(mockSession: session).getCustomers()
            XCTAssertNotNil(customersTwo)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomer() async {
        let customer = try? await CustomersAPI(mockSession: session).getCustomerWith(customerId: "")
        XCTAssertNil(customer)
        
        let customerTwo = try? await CustomersAPI(mockSession: session).getCustomerWith(customerId: "123")
        XCTAssertNil(customerTwo)
        
        do {
            session.data = try JSONEncoder().encode(Frame_iOS.FrameObjects.Customer(id: "1234", livemode: false, name: "Tester"))
            let customerThree = try await CustomersAPI(mockSession: session).getCustomerWith(customerId: "1234")
            XCTAssertNotNil(customerThree)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testSearchCustomers() async {
        var request = CustomerRequest.SearchCustomersRequest()
        let firstSearch = try? await CustomersAPI(mockSession: session).searchCustomers(request: request)
        XCTAssertNil(firstSearch)
        
        XCTAssertNil(request.name)
        request.name = "Tester"
        XCTAssertNotNil(request.name)
        
        XCTAssertNil(request.email)
        request.email = "tester@gmail.com"
        XCTAssertNotNil(request.email)
        
        XCTAssertNil(request.phone)
        request.phone = "999-999-9999"
        XCTAssertNotNil(request.phone)
        
        do {
            let response = Frame_iOS.CustomerResponses.ListCustomersResponse(data: [Frame_iOS.FrameObjects.Customer(id: "1234", livemode: false, name: "Tester"),
                                                                                    Frame_iOS.FrameObjects.Customer(id: "12345", livemode: false, name: "Tester2")])
            
            session.data = try JSONEncoder().encode(response)
            let secondSearch = try await CustomersAPI(mockSession: session).searchCustomers(request: request)
            XCTAssertNotNil(secondSearch)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
