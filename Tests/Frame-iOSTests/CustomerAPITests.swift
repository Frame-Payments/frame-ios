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
        FrameNetworking.shared.asyncURLSession = session
        
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
        
        let createdCustomer = try? await CustomersAPI.createCustomer(request: request).0
        XCTAssertNil(createdCustomer)
        
        var customer = FrameObjects.Customer(id: "1", livemode: false, name: "Tester")
        customer.description = "New Customer"
        customer.phone = "999-999-9999"
        customer.billingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        customer.shippingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "11111", addressLine1: nil, addressLine2: nil)
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let (createdCustomerTwo, _) = try await CustomersAPI.createCustomer(request: request)
            XCTAssertNotNil(createdCustomerTwo)
            XCTAssertEqual(createdCustomerTwo?.phone, customer.phone)
            XCTAssertEqual(createdCustomerTwo?.billingAddress, customer.billingAddress)
            XCTAssertEqual(createdCustomerTwo?.shippingAddress, customer.shippingAddress)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testDeleteCustomer() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let customerResponse = try? await CustomersAPI.deleteCustomer(customerId: "").0
        XCTAssertNil(customerResponse)
        
        let customerTwoResponse = try? await CustomersAPI.deleteCustomer(customerId: "123").0
        XCTAssertNil(customerTwoResponse)
        
        let response = CustomerResponses.DeleteCustomerResponse(id: "1234", object: "customer", deleted: true)
        do {
            session.data = try? JSONEncoder().encode(response)
            let (customerThreeResponse, _) = try await CustomersAPI.deleteCustomer(customerId: "1234")
            XCTAssertNotNil(customerThreeResponse)
            XCTAssertEqual(customerThreeResponse?.id, response.id)
        } catch {
            XCTFail("Error shoud not be thrown")
        }
    }
    
    func testUpdateCustomer() async {
        FrameNetworking.shared.asyncURLSession = session
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
        
        let updatedCustomer = try? await CustomersAPI.updateCustomerWith(customerId: "", request: request).0
        XCTAssertNil(updatedCustomer)
        
        let updatedCustomerTwo = try? await CustomersAPI.updateCustomerWith(customerId: "123", request: request).0
        XCTAssertNil(updatedCustomerTwo)
        
        var customer = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester")
        customer.phone = "999-999-9999"
        customer.description = "Testing"
        customer.billingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "99999", addressLine1: nil, addressLine2: nil)
        customer.shippingAddress = FrameObjects.BillingAddress(city: nil, country: nil, state: nil, postalCode: "11111", addressLine1: nil, addressLine2: nil)
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let (customerThree, _) = try await CustomersAPI.updateCustomerWith(customerId: "1234", request: request)
            XCTAssertNotNil(customerThree)
            XCTAssertEqual(customerThree?.billingAddress, customer.billingAddress)
            XCTAssertEqual(customerThree?.shippingAddress, customer.shippingAddress)
            XCTAssertEqual(customerThree?.phone, customer.phone)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomers() async {
        FrameNetworking.shared.asyncURLSession = session
        let customers = try? await CustomersAPI.getCustomers().0
        XCTAssertNil(customers)
        
        let customerOne = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester")
        let customerTwo = FrameObjects.Customer(id: "12345", livemode: false, name: "Tester2")
        do {
            let response = Frame_iOS.CustomerResponses.ListCustomersResponse(meta: nil, data: [customerOne, customerTwo])
            
            session.data = try JSONEncoder().encode(response)
            let (customersTwo, _) = try await CustomersAPI.getCustomers()
            XCTAssertNotNil(customersTwo)
            XCTAssertEqual(customersTwo?.data?[0].id, customerOne.id)
            XCTAssertEqual(customersTwo?.data?[1].id, customerTwo.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetCustomerWithId() async {
        FrameNetworking.shared.asyncURLSession = session
        let receivedCustomer = try? await CustomersAPI.getCustomerWith(customerId: "").0
        XCTAssertNil(receivedCustomer)
        
        let receivedCustomerTwo = try? await CustomersAPI.getCustomerWith(customerId: "123").0
        XCTAssertNil(receivedCustomerTwo)
        
        let customer = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester")
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let (receivedCustomerThree, _) = try await CustomersAPI.getCustomerWith(customerId: "1234")
            XCTAssertNotNil(receivedCustomerThree)
            XCTAssertEqual(receivedCustomerThree?.id, customer.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testSearchCustomers() async {
        FrameNetworking.shared.asyncURLSession = session
        var request = CustomerRequest.SearchCustomersRequest()
        let firstSearch = try? await CustomersAPI.searchCustomers(request: request).0
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
            let response = CustomerResponses.ListCustomersResponse(meta: nil, data: [customerOne, customerTwo])
            
            session.data = try JSONEncoder().encode(response)
            let (secondSearch, _) = try await CustomersAPI.searchCustomers(request: request)
            XCTAssertNotNil(secondSearch)
            XCTAssertEqual(secondSearch?[0].name, customerOne.name)
            XCTAssertEqual(secondSearch?[1].name, customerTwo.name)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testBlockCustomerWithId() async {
        FrameNetworking.shared.asyncURLSession = session
        let receivedCustomer = try? await CustomersAPI.blockCustomerWith(customerId: "").0
        XCTAssertNil(receivedCustomer)
        
        let receivedCustomerTwo = try? await CustomersAPI.blockCustomerWith(customerId: "123").0
        XCTAssertNil(receivedCustomerTwo)
        
        let customer = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester", status: .blocked)
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let (receivedCustomerThree, _) = try await CustomersAPI.blockCustomerWith(customerId: "1234")
            XCTAssertNotNil(receivedCustomerThree)
            XCTAssertEqual(receivedCustomerThree?.id, customer.id)
            XCTAssertEqual(receivedCustomerThree?.status, customer.status)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUnblockCustomerWithId() async {
        FrameNetworking.shared.asyncURLSession = session
        let receivedCustomer = try? await CustomersAPI.unblockCustomerWith(customerId: "").0
        XCTAssertNil(receivedCustomer)
        
        let receivedCustomerTwo = try? await CustomersAPI.unblockCustomerWith(customerId: "123").0
        XCTAssertNil(receivedCustomerTwo)
        
        let customer = FrameObjects.Customer(id: "1234", livemode: false, name: "Tester", status: .active)
        
        do {
            session.data = try JSONEncoder().encode(customer)
            let (receivedCustomerThree, _) = try await CustomersAPI.unblockCustomerWith(customerId: "1234")
            XCTAssertNotNil(receivedCustomerThree)
            XCTAssertEqual(receivedCustomerThree?.id, customer.id)
            XCTAssertEqual(receivedCustomerThree?.status, customer.status)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
