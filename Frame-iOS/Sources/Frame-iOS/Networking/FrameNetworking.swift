//
//  FrameAuth.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
//

// https://docs.framepayments.com/authentication

import SwiftUI

// Create Network Request Here That Return Callbacks With User Data, This is the "Router"

// TODO: Add Pagination for Network Request

public class FrameNetworking: ObservableObject {
    nonisolated(unsafe) static let shared = FrameNetworking()
    
    let apiKey: String? // API Key used to authenticate each request - Bearer Token
    
    init(_ apiKey: String? = nil) {
        self.apiKey = apiKey
    }
    
    func performDataTask(request: URLRequest, completion: @escaping (Data?, URLResponse?, (any Error)?) -> Void) {
        URLSession(configuration: .default).dataTask(with: request) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
}
