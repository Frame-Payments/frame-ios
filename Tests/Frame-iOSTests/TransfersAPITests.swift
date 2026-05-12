//
//  TransfersAPITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import XCTest
@testable import Frame

final class TransfersAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/transfers")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)

    let transferResponse = FrameObjects.Transfer(id: "tr_1",
                                                 object: "transfer",
                                                 status: .pending,
                                                 amount: 10000,
                                                 currency: "USD",
                                                 platformFee: 100,
                                                 frameFee: 15,
                                                 totalFees: 115,
                                                 netAmount: 10000,
                                                 billingAgreement: "ba_1",
                                                 livemode: true,
                                                 created: 0)

    func testCreateTransfer() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = TransferRequests.CreateTransferRequest(amount: 10000,
                                                             accountId: "acc_123",
                                                             currency: "USD",
                                                             sourcePaymentMethodId: "pm_123")
        XCTAssertEqual(request.amount, 10000)
        XCTAssertEqual(request.accountId, "acc_123")
        XCTAssertEqual(request.sourcePaymentMethodId, "pm_123")

        let transferOne = try? await TransfersAPI.createTransfer(request: request).0
        XCTAssertNil(transferOne)

        do {
            session.data = try JSONEncoder().encode(transferResponse)
            let (transferTwo, _) = try await TransfersAPI.createTransfer(request: request)
            XCTAssertNotNil(transferTwo)
            XCTAssertEqual(transferTwo?.id, transferResponse.id)
            XCTAssertEqual(transferTwo?.amount, transferResponse.amount)
            XCTAssertEqual(transferTwo?.status, transferResponse.status)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }

    func testGetTransferWith() async {
        FrameNetworking.shared.asyncURLSession = session

        let transferOne = try? await TransfersAPI.getTransferWith(transferId: "").0
        XCTAssertNil(transferOne)

        let transferTwo = try? await TransfersAPI.getTransferWith(transferId: "tr_123").0
        XCTAssertNil(transferTwo)

        do {
            session.data = try JSONEncoder().encode(transferResponse)
            let (transferThree, _) = try await TransfersAPI.getTransferWith(transferId: "tr_1")
            XCTAssertNotNil(transferThree)
            XCTAssertEqual(transferThree?.id, transferResponse.id)
            XCTAssertEqual(transferThree?.billingAgreement, transferResponse.billingAgreement)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }

    func testGetTransfers() async {
        FrameNetworking.shared.asyncURLSession = session

        let transfersOne = try? await TransfersAPI.getTransfers().0
        XCTAssertNil(transfersOne)

        let transferTwo = FrameObjects.Transfer(id: "tr_2",
                                                object: "transfer",
                                                status: .completed,
                                                amount: 5000,
                                                currency: "USD",
                                                livemode: false,
                                                created: 1)
        do {
            session.data = try JSONEncoder().encode(TransferResponses.ListTransfersResponse(meta: nil, data: [transferResponse, transferTwo]))
            let (transfersTwo, _) = try await TransfersAPI.getTransfers(perPage: 10, page: 1)

            XCTAssertNotNil(transfersTwo)
            XCTAssertEqual(transfersTwo?.data?[0].id, transferResponse.id)
            XCTAssertEqual(transfersTwo?.data?[1].status, .completed)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
