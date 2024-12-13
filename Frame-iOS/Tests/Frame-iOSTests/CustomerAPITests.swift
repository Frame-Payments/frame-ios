//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/24.
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
        
        let createdCustomer = try? await CustomersAPI(mockSession: session).createCustomer(request: request)
        XCTAssertNil(createdCustomer)
        
        var customer = FrameObjects.Customer(id: "1", livemode: false, name: "Tester")
        customer.description = "New Customer"
        customer.phone = "999-999-9999"
        customer.billingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        customer.shippingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "11111", addressLine1: nil, addressLine2: nil)
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let createdCustomerTwo = try await CustomersAPI(mockSession: session).createCustomer(request: request)
            XCTAssertNotNil(createdCustomerTwo)
            XCTAssertEqual(createdCustomerTwo?.phone, customer.phone)
            XCTAssertEqual(createdCustomerTwo?.billingAddress, customer.billingAddress)
            XCTAssertEqual(createdCustomerTwo?.shippingAddress, customer.shippingAddress)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testDeleteCustomer() async {
        let customerResponse = try? await CustomersAPI(mockSession: session).deleteCustomer(customerId: "")
        XCTAssertNil(customerResponse)
        
        let customerTwoResponse = try? await CustomersAPI(mockSession: session).deleteCustomer(customerId: "123")
        XCTAssertNil(customerTwoResponse)
        
        let response = CustomerResponses.DeleteCustomerResponse(id: "1234", object: nil, deleted: nil)
        session.data = try? JSONEncoder().encode(response)
        let customerThreeResponse = try? await CustomersAPI(mockSession: session).deleteCustomer(customerId: "1234")
        XCTAssertNotNil(customerThreeResponse)
        XCTAssertEqual(customerThreeResponse?.id, response.id)
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
        request.shippingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "11111", addressLine1: nil, addressLine2: nil)
        XCTAssertNotNil(request.shippingAddress)
        
        let updatedCustomer = try? await CustomersAPI(mockSession: session).updateCustomerWith(customerId: "", request: request)
        XCTAssertNil(updatedCustomer)
        
        let updatedCustomerTwo = try? await CustomersAPI(mockSession: session).updateCustomerWith(customerId: "123", request: request)
        XCTAssertNil(updatedCustomerTwo)
        
        var customer = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester")
        customer.phone = "999-999-9999"
        customer.description = "Testing"
        customer.billingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        customer.shippingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "11111", addressLine1: nil, addressLine2: nil)
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let customerThree = try await CustomersAPI(mockSession: session).updateCustomerWith(customerId: "1234", request: request)
            XCTAssertNotNil(customerThree)
            XCTAssertEqual(customerThree?.billingAddress, customer.billingAddress)
            XCTAssertEqual(customerThree?.shippingAddress, customer.shippingAddress)
            XCTAssertEqual(customerThree?.phone, customer.phone)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomers() async {
        let customers = try? await CustomersAPI(mockSession: session).getCustomers()
        XCTAssertNil(customers)
        
        let customerOne = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester")
        let customerTwo = FrameObjects.Customer(id: "12345", livemode: false, name: "Tester2")
        do {
            let response = Frame_iOS.CustomerResponses.ListCustomersResponse(data: [customerOne, customerTwo])
            
            session.data = try JSONEncoder().encode(response)
            let customersTwo = try await CustomersAPI(mockSession: session).getCustomers()
            XCTAssertNotNil(customersTwo)
            XCTAssertEqual(customersTwo?[0].id, customerOne.id)
            XCTAssertEqual(customersTwo?[1].id, customerTwo.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomer() async {
        let receivedCustomer = try? await CustomersAPI(mockSession: session).getCustomerWith(customerId: "")
        XCTAssertNil(receivedCustomer)
        
        let receivedCustomerTwo = try? await CustomersAPI(mockSession: session).getCustomerWith(customerId: "123")
        XCTAssertNil(receivedCustomerTwo)
        
        let customer = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester")
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let receivedCustomerThree = try await CustomersAPI(mockSession: session).getCustomerWith(customerId: "1234")
            XCTAssertNotNil(receivedCustomerThree)
            XCTAssertEqual(receivedCustomerThree?.id, customer.id)
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
        
        let customerOne = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester")
        let customerTwo = FrameObjects.Customer(id: "12345", livemode: false, name: "Tester2")
        
        do {
            let response = Frame_iOS.CustomerResponses.ListCustomersResponse(data: [customerOne, customerTwo])
            
            session.data = try JSONEncoder().encode(response)
            let secondSearch = try await CustomersAPI(mockSession: session).searchCustomers(request: request)
            XCTAssertNotNil(secondSearch)
            XCTAssertEqual(secondSearch?[0].name, customerOne.name)
            XCTAssertEqual(secondSearch?[1].name, customerTwo.name)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
