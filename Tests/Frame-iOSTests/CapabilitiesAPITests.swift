//
//  CapabilitiesAPITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import XCTest
@testable import Frame

final class CapabilitiesAPITests: XCTestCase {
    let session = MockURLAsyncSession(
        data: nil,
        response: HTTPURLResponse(
            url: URL(string: "https://api.framepayments.com/v1/accounts/acc_123/capabilities")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ),
        error: nil
    )
    
    func testGetCapabilities() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let response = try? await CapabilitiesAPI.getCapabilities(accountId: "").0
        XCTAssertNil(response)
        
        let responseTwo = try? await CapabilitiesAPI.getCapabilities(accountId: "acc_123").0
        XCTAssertNil(responseTwo)
        
        let capability = FrameObjects.Capability(
            id: "cap_1",
            object: "capability",
            name: "card_send",
            status: "active",
            disabledReason: nil,
            requirements: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890
        )
        let listResponse = CapabilityResponses.ListCapabilitiesResponse(data: [capability])
        
        do {
            session.data = try JSONEncoder().encode(listResponse)
            let (capabilitiesResponse, _) = try await CapabilitiesAPI.getCapabilities(accountId: "acc_123")
            XCTAssertNotNil(capabilitiesResponse)
            XCTAssertEqual(capabilitiesResponse?.data?.first?.name, "card_send")
            XCTAssertEqual(capabilitiesResponse?.data?.first?.status, "active")
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
    
    func testRequestCapabilities() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let request = CapabilityRequest.RequestCapabilitiesRequest(capabilities: ["card_send"])
        let response = try? await CapabilitiesAPI.requestCapabilities(accountId: "", request: request).0
        XCTAssertNil(response)
        
        let responseTwo = try? await CapabilitiesAPI.requestCapabilities(accountId: "acc_123", request: request).0
        XCTAssertNil(responseTwo)
        
        let capability = FrameObjects.Capability(
            id: "cap_1",
            object: "capability",
            name: "card_send",
            status: "pending",
            disabledReason: nil,
            requirements: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890
        )
        
        do {
            session.data = try JSONEncoder().encode([capability])
            let (capabilities, _) = try await CapabilitiesAPI.requestCapabilities(accountId: "acc_123", request: request)
            XCTAssertNotNil(capabilities)
            XCTAssertEqual(capabilities?.first?.name, "card_send")
            XCTAssertEqual(capabilities?.first?.status, "pending")
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
    
    func testGetCapabilityWith() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let response = try? await CapabilitiesAPI.getCapabilityWith(accountId: "", name: "card_send").0
        XCTAssertNil(response)
        
        let responseTwo = try? await CapabilitiesAPI.getCapabilityWith(accountId: "acc_123", name: "").0
        XCTAssertNil(responseTwo)
        
        let capability = FrameObjects.Capability(
            id: "cap_1",
            object: "capability",
            name: "card_send",
            status: "active",
            disabledReason: nil,
            requirements: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890
        )
        
        do {
            session.data = try JSONEncoder().encode(capability)
            let (capabilityResponse, _) = try await CapabilitiesAPI.getCapabilityWith(accountId: "acc_123", name: "card_send")
            XCTAssertNotNil(capabilityResponse)
            XCTAssertEqual(capabilityResponse?.name, "card_send")
            XCTAssertEqual(capabilityResponse?.status, "active")
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
    
    func testDisableCapabilityWith() async {
        FrameNetworking.shared.asyncURLSession = session
        
        let response = try? await CapabilitiesAPI.disableCapabilityWith(accountId: "", name: "card_send").0
        XCTAssertNil(response)
        
        let responseTwo = try? await CapabilitiesAPI.disableCapabilityWith(accountId: "acc_123", name: "").0
        XCTAssertNil(responseTwo)
        
        let capability = FrameObjects.Capability(
            id: "cap_1",
            object: "capability",
            name: "card_send",
            status: "disabled",
            disabledReason: "User requested",
            requirements: nil,
            createdAt: 1234567890,
            updatedAt: 1234567890
        )
        
        do {
            session.data = try JSONEncoder().encode(capability)
            let (capabilityResponse, _) = try await CapabilitiesAPI.disableCapabilityWith(accountId: "acc_123", name: "card_send")
            XCTAssertNotNil(capabilityResponse)
            XCTAssertEqual(capabilityResponse?.name, "card_send")
            XCTAssertEqual(capabilityResponse?.status, "disabled")
        } catch {
            XCTFail("Error should not be thrown: \(error)")
        }
    }
}
