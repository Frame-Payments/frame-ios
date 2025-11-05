//
//  InvoiceLineItemsAPITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/3/24.
//

import XCTest
@testable import Frame_iOS

final class InvoiceLineItemsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/invoices/inv_1/line_items")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    var invoiceLineItemResponse: FrameObjects.InvoiceLineItem = FrameObjects.InvoiceLineItem(id: "item_1", object: "line_item",
                                                                                             description: "New Line Item", quantity: 5,
                                                                                             unitAmountCents: 100, unitAmountCurrency: "usd",
                                                                                             created: 0, updated: 0)
    
    func testCreateInvoiceLineItem() async {
        FrameNetworking.shared.asyncURLSession = session
        var request = InvoiceLineItemRequests.CreateLineItemRequest(product: "prod_1", quantity: 5)
        XCTAssertNotNil(request.product)
        XCTAssertNotNil(request.quantity)
        
        let createdLineItem = try? await InvoiceLineItemsAPI.createLineItem(invoiceId: "inv_1", request: request).0
        XCTAssertNil(createdLineItem)
        
        do {
            session.data = try JSONEncoder().encode(invoiceLineItemResponse)
            let (createdLineItemTwo, _) = try await InvoiceLineItemsAPI.createLineItem(invoiceId: "inv_1", request: request)
            XCTAssertNotNil(createdLineItemTwo)
            XCTAssertEqual(createdLineItemTwo?.id, invoiceLineItemResponse.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateInvoiceLineItem() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = InvoiceLineItemRequests.UpdateLineItemRequest(quantity: 10)
        XCTAssertNotNil(request.quantity)
        
        let createdInvoice = try? await InvoiceLineItemsAPI.updateLineItem(invoiceId: "inv_1", itemId: "item_1", request: request).0
        XCTAssertNil(createdInvoice)
        
        do {
            session.data = try JSONEncoder().encode(invoiceLineItemResponse)
            let (createdInvoiceTwo, _) = try await InvoiceLineItemsAPI.updateLineItem(invoiceId: "inv_1", itemId: "item_1", request: request)
            XCTAssertNotNil(createdInvoiceTwo)
            XCTAssertNotEqual(createdInvoiceTwo?.quantity, 10)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetInvoiceLineItem() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let invoiceLineItem = try? await InvoiceLineItemsAPI.getLineItem(invoiceId: "inv_1", itemId: "item_1").0
        XCTAssertNil(invoiceLineItem)
        
        do {
            session.data = try JSONEncoder().encode(invoiceLineItemResponse)
            let (invoiceLineItemTwo, _) = try await InvoiceLineItemsAPI.getLineItem(invoiceId: "inv_1", itemId: "item_1")
            XCTAssertNotNil(invoiceLineItemTwo)
            XCTAssertEqual(invoiceLineItemTwo?.id, invoiceLineItemResponse.id)
            XCTAssertEqual(invoiceLineItemTwo?.unitAmountCurrency, invoiceLineItemResponse.unitAmountCurrency)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetInvoiceLineItems() async {
        FrameNetworking.shared.asyncURLSession = session
        let invoiceLineItems = try? await InvoiceLineItemsAPI.getLineItems(invoiceId: "inv_1").0
        XCTAssertNil(invoiceLineItems )

        let response = InvoiceLineItemResponses.ListLineItemsResponse(data: [invoiceLineItemResponse])
        do {
            session.data = try JSONEncoder().encode(response)
            let (invoiceLineItemsTwo, _) = try await InvoiceLineItemsAPI.getLineItems(invoiceId: "inv_1")
            XCTAssertNotNil(invoiceLineItemsTwo)
            XCTAssertEqual(invoiceLineItemsTwo?.data?[0].id, invoiceLineItemResponse.id)
            XCTAssertEqual(invoiceLineItemsTwo?.data?[0].unitAmountCents, invoiceLineItemResponse.unitAmountCents)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testDeleteInvoiceLineItem() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let deletedInvoice = try? await InvoiceLineItemsAPI.deleteLineItem(invoiceId: "inv_1", itemId: "item_1").0
        XCTAssertNil(deletedInvoice)
        
        let deletedResponse = InvoiceLineItemResponses.DeleteLineItemResponse(object: "invoice", deleted: true)
        do {
            session.data = try JSONEncoder().encode(deletedResponse)
            let (deletedInvoiceLineItemTwo, _) = try await InvoiceLineItemsAPI.deleteLineItem(invoiceId: "inv_1", itemId: "item_1")
            XCTAssertNotNil(deletedInvoiceLineItemTwo)
            XCTAssertEqual(deletedInvoiceLineItemTwo?.deleted, true)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}


