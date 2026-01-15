//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/3/24.
//

import XCTest
@testable import Frame

final class InvoicesAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/invoices")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    var invoiceResponse: FrameObjects.Invoice = FrameObjects.Invoice(id: "inv_1",
                                                                     customer: FrameObjects.Customer(id: "cus_123",
                                                                                                     livemode: true,
                                                                                                     name: "Test customer"),
                                                                     object: "invoice",
                                                                     total: 100,
                                                                     currency: "usd",
                                                                     status: .outstanding,
                                                                     collectionMethod: .autoCharge,
                                                                     netTerms: 30,
                                                                     invoiceNumber: "1",
                                                                     description: "New Invoice",
                                                                     memo: "memo",
                                                                     livemode: true,
                                                                     metadata: nil,
                                                                     lineItems: [FrameObjects.Invoice.InvoiceLineItem(object: "line_item",
                                                                                                                      id: "item_1",
                                                                                                                      quantity: 20,
                                                                                                                      product: FrameObjects.Invoice.InvoiceProduct(object: "product",
                                                                                                                                                                   id: "prod_1",
                                                                                                                                                                   name: "new product",
                                                                                                                                                                   price: 100))],
                                                                     created: 0,
                                                                     updated: 0)
    
    func testCreateInvoice() async {
        FrameNetworking.shared.asyncURLSession = session
        var request = InvoiceRequests.CreateInvoiceRequest(customer: "cus_123", collectionMethod: .autoCharge)
        XCTAssertNotNil(request.customer)
        XCTAssertNotNil(request.collectionMethod)
        
        XCTAssertNil(request.description)
        request.description = "New Invoice"
        XCTAssertNotNil(request.description)
        
        XCTAssertNil(request.lineItems)
        request.lineItems = [FrameObjects.Invoice.InvoiceLineItem(object: "line_item",
                                                                       id: "item_1",
                                                                       quantity: 20,
                                                                       product: FrameObjects.Invoice.InvoiceProduct(object: "product",
                                                                                                                    id: "prod_1",
                                                                                                                    name: "new product",
                                                                                                                    price: 100))]
        XCTAssertNotNil(request.lineItems)
        
        let createdInvoice = try? await InvoicesAPI.createInvoice(request: request).0
        XCTAssertNil(createdInvoice)
        
        do {
            session.data = try JSONEncoder().encode(invoiceResponse)
            let (createdInvoiceTwo, _) = try await InvoicesAPI.createInvoice(request: request)
            XCTAssertNotNil(createdInvoiceTwo)
            XCTAssertEqual(createdInvoiceTwo?.lineItems?.count, 1)
            XCTAssertEqual(createdInvoiceTwo?.currency, "usd")
            XCTAssertEqual(createdInvoiceTwo?.collectionMethod, .autoCharge)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateInvoice() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = InvoiceRequests.UpdateInvoiceRequest(collectionMethod: .requestPayment)
        XCTAssertNotNil(request.collectionMethod)
        
        let createdInvoice = try? await InvoicesAPI.updateInvoice(invoiceId: "inv_1", request: request).0
        XCTAssertNil(createdInvoice)
        
        do {
            session.data = try JSONEncoder().encode(invoiceResponse)
            let (createdInvoiceTwo, _) = try await InvoicesAPI.updateInvoice(invoiceId: "inv_1", request: request)
            XCTAssertNotNil(createdInvoiceTwo)
            XCTAssertEqual(createdInvoiceTwo?.collectionMethod, .autoCharge)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetInvoice() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let newInvoice = try? await InvoicesAPI.getInvoice(invoiceId: "inv_1").0
        XCTAssertNil(newInvoice)
        
        do {
            session.data = try JSONEncoder().encode(invoiceResponse)
            let (newInvoiceTwo, _) = try await InvoicesAPI.getInvoice(invoiceId: "inv_1")
            XCTAssertNotNil(newInvoiceTwo)
            XCTAssertEqual(newInvoiceTwo?.total, 100)
            XCTAssertEqual(newInvoiceTwo?.currency, "usd")
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetInvoices() async {
        FrameNetworking.shared.asyncURLSession = session
        let invoices = try? await InvoicesAPI.getInvoices().0
        XCTAssertNil(invoices)

        do {
            let response = InvoiceResponses.ListInvoicesResponse(meta: nil, data: [invoiceResponse])

            session.data = try JSONEncoder().encode(response)
            let (invoicesTwo, _) = try await InvoicesAPI.getInvoices()
            XCTAssertNotNil(invoicesTwo)
            XCTAssertEqual(invoicesTwo?.data?[0].id, invoiceResponse.id)
            XCTAssertEqual(invoicesTwo?.data?[0].invoiceNumber, invoiceResponse.invoiceNumber)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testDeleteInvoice() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let deletedInvoice = try? await InvoicesAPI.deleteInvoice(invoiceId: "inv_1").0
        XCTAssertNil(deletedInvoice)
        
        let deletedResponse = InvoiceResponses.DeleteInvoiceResponse(object: "invoice", deleted: true)
        do {
            session.data = try JSONEncoder().encode(deletedResponse)
            let (deletedInvoiceTwo, _) = try await InvoicesAPI.deleteInvoice(invoiceId: "inv_1")
            XCTAssertNotNil(deletedInvoiceTwo)
            XCTAssertEqual(deletedInvoiceTwo?.deleted, true)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testIssueInvoice() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let newInvoice = try? await InvoicesAPI.issueInvoice(invoiceId: "inv_1").0
        XCTAssertNil(newInvoice)
        
        invoiceResponse.status = .open
        
        do {
            session.data = try JSONEncoder().encode(invoiceResponse)
            let (newInvoiceTwo, _) = try await InvoicesAPI.issueInvoice(invoiceId: "inv_1")
            XCTAssertNotNil(newInvoiceTwo)
            XCTAssertEqual(newInvoiceTwo?.status, .open)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
