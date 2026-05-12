//
//  TransferResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

public class TransferResponses {
    public struct ListTransfersResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.Transfer]?
    }
}
