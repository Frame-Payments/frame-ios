//
//  TransfersV2APITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import XCTest
@testable import Frame

final class TransfersV2APITests: XCTestCase {
    let session = MockURLAsyncSession(
        data: nil,
        response: HTTPURLResponse(
            url: URL(string: "https://api.framepayments.com/v2/transfers")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        ),
        error: nil
    )

    let transferResponse = FrameObjects.TransferV2(
        id: "tr_v2_1",
        object: "transfer",
        type: .payment,
        status: .pending,
        amount: .init(value: 10000, currency: "usd"),
        fee: .init(value: 30, currency: "usd"),
        netAmount: .init(value: 9970, currency: "usd"),
        livemode: false,
        created: 1700000000
    )

    private func makeCreateRequest() -> TransferV2Requests.CreateTransferRequest {
        TransferV2Requests.CreateTransferRequest(
            amount: .init(value: 10000, currency: "usd"),
            source: .init(accountId: "acc_123", paymentMethodId: "pm_123"),
            confirm: false,
            authorizationMode: "automatic"
        )
    }

    func testCreateTransfer() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = makeCreateRequest()
        XCTAssertEqual(request.amount.value, 10000)
        XCTAssertEqual(request.source?.paymentMethodId, "pm_123")

        let transferOne = try? await TransfersV2API.createTransfer(request: request).0
        XCTAssertNil(transferOne)

        do {
            session.data = try JSONEncoder().encode(transferResponse)
            let (transferTwo, _) = try await TransfersV2API.createTransfer(
                request: request,
                idempotencyKey: "key-1"
            )
            XCTAssertNotNil(transferTwo)
            XCTAssertEqual(transferTwo?.id, transferResponse.id)
            XCTAssertEqual(transferTwo?.amount?.value, 10000)
            XCTAssertEqual(transferTwo?.type, .payment)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }

    func testCreateTransferIdempotencyHeaderOnEndpoint() {
        let endpoint = TransferV2Endpoints.createTransfer(idempotencyKey: "abc-123")
        XCTAssertEqual(endpoint.additionalHeaders["Idempotency-Key"], "abc-123")
        XCTAssertEqual(endpoint.endpointURL, "/v2/transfers")
        XCTAssertEqual(endpoint.httpMethod, .POST)
    }

    func testMemberEndpoints() {
        let confirm = TransferV2Endpoints.confirmTransfer(transferId: "tr_1", idempotencyKey: "k1")
        XCTAssertEqual(confirm.endpointURL, "/v2/transfers/tr_1/confirm")
        XCTAssertEqual(confirm.additionalHeaders["Idempotency-Key"], "k1")

        let publishableConfirm = TransferV2Endpoints.confirmTransfer(transferId: "tr_1", idempotencyKey: nil)
        XCTAssertTrue(publishableConfirm.additionalHeaders.isEmpty)

        let capture = TransferV2Endpoints.captureTransfer(transferId: "tr_1", idempotencyKey: "k2")
        XCTAssertEqual(capture.httpMethod, .POST)
        XCTAssertEqual(capture.additionalHeaders["Idempotency-Key"], "k2")

        XCTAssertEqual(
            TransferV2Endpoints.updateTransfer(transferId: "tr_1").httpMethod,
            .PATCH
        )
        XCTAssertEqual(
            TransferV2Endpoints.voidTransfer(transferId: "tr_1", idempotencyKey: "k3").endpointURL,
            "/v2/transfers/tr_1/void"
        )
        XCTAssertEqual(
            TransferV2Endpoints.refundTransfer(transferId: "tr_1", idempotencyKey: "k4").endpointURL,
            "/v2/transfers/tr_1/refund"
        )
    }

    func testGetTransferWith() async {
        FrameNetworking.shared.asyncURLSession = session

        let empty = try? await TransfersV2API.getTransferWith(transferId: "").0
        XCTAssertNil(empty)

        do {
            session.data = try JSONEncoder().encode(transferResponse)
            let (transfer, _) = try await TransfersV2API.getTransferWith(transferId: "tr_v2_1")
            XCTAssertEqual(transfer?.id, transferResponse.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }

    func testCreateTransferReturnsServerError() async {
        let badSession = MockURLAsyncSession(
            data: "{\"error\":\"idempotency_key_required\"}".data(using: .utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://api.framepayments.com/v2/transfers")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            ),
            error: nil
        )
        FrameNetworking.shared.asyncURLSession = badSession

        do {
            let (transfer, error) = try await TransfersV2API.createTransfer(request: makeCreateRequest())
            XCTAssertNil(transfer)
            if case .serverError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 400)
            } else {
                XCTFail("Expected NetworkingError.serverError, got \(String(describing: error))")
            }
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }

    func testTransferV2DecodesNestedMoneyFromBackendPayload() throws {
        let json = """
        {
          "id":"tr_v2_1",
          "object":"transfer",
          "type":"payment",
          "status":"pending",
          "amount":{"value":15000,"currency":"usd"},
          "fee":{"value":45,"currency":"usd"},
          "net_amount":{"value":14955,"currency":"usd"},
          "payment":{"status":"succeeded","authorization_mode":"automatic"}
        }
        """.data(using: .utf8)!
        let transfer = try JSONDecoder().decode(FrameObjects.TransferV2.self, from: json)
        XCTAssertEqual(transfer.amount?.value, 15000)
        XCTAssertEqual(transfer.payment?.status, "succeeded")
        XCTAssertEqual(transfer.type, .payment)
    }

    func testCreateTransferReturnsDecodingFailedOnMalformedBody() async {
        let malformedSession = MockURLAsyncSession(
            data: "{\"id\":123}".data(using: .utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://api.framepayments.com/v2/transfers")!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            ),
            error: nil
        )
        FrameNetworking.shared.asyncURLSession = malformedSession

        do {
            let (transfer, error) = try await TransfersV2API.createTransfer(request: makeCreateRequest())
            XCTAssertNil(transfer)
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }

    func testConfirmCaptureVoidRefund() async {
        FrameNetworking.shared.asyncURLSession = session
        do {
            session.data = try JSONEncoder().encode(transferResponse)
            let (confirmed, _) = try await TransfersV2API.confirmTransfer(transferId: "tr_v2_1")
            XCTAssertEqual(confirmed?.id, "tr_v2_1")

            let (captured, _) = try await TransfersV2API.captureTransfer(
                transferId: "tr_v2_1",
                request: .init(amount: .init(value: 5000, currency: "usd"))
            )
            XCTAssertEqual(captured?.id, "tr_v2_1")

            let (voided, _) = try await TransfersV2API.voidTransfer(transferId: "tr_v2_1")
            XCTAssertEqual(voided?.id, "tr_v2_1")

            let (refunded, _) = try await TransfersV2API.refundTransfer(transferId: "tr_v2_1")
            XCTAssertEqual(refunded?.id, "tr_v2_1")
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
}
