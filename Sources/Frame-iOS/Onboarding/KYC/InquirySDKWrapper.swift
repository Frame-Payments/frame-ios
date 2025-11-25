//
//  File.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/20/25.
//

import Foundation
import Persona2
import SwiftUI
import UIKit

struct InquirySDKWrapper: UIViewControllerRepresentable {
    private let wrapperVC: WrapperViewController
    
    init(
        inquiryComplete: @escaping (String, String, [String: InquiryField]) -> Void,
        inquiryCanceled: @escaping (_ inquiryId: String?, _ sessionToken: String?) -> Void,
        inquiryErrored: @escaping (_ error: Error) -> Void
    ) {
        wrapperVC = WrapperViewController()
        wrapperVC.inquiryComplete = inquiryComplete
        wrapperVC.inquiryCanceled = inquiryCanceled
        wrapperVC.inquiryErrored = inquiryErrored
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return wrapperVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}


final class WrapperViewController: UIViewController {
    
    private var isPresenting = false
    
    // The callbacks
    var inquiryComplete: ((_ inquiryId: String, _ status: String, _ fields: [String: InquiryField]) -> Void)!
    var inquiryCanceled: ((_ inquiryId: String?, _ sessionToken: String?) -> Void)!
    var inquiryErrored: ((_ error: Error) -> Void)!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !isPresenting else { return }
        
        let inquiry = Inquiry(config: InquiryConfiguration(templateId: "itmpl_4LsXisNzDy5t57gisrfRvEUeiUoo"),
                              delegate: self)
        inquiry.start(from: self)
        
        isPresenting = true
    }
}

extension WrapperViewController: InquiryDelegate {

    func inquiryComplete(inquiryId: String, status: String, fields: [String: InquiryField]) {
        inquiryComplete(inquiryId, status, fields)
        dismiss(animated: true, completion: nil)
    }

    func inquiryCanceled(inquiryId: String?, sessionToken: String?) {
        inquiryCanceled(inquiryId, sessionToken)
        dismiss(animated: true, completion: nil)
    }

    func inquiryError(_ error: Error) {
        inquiryErrored(error)
        dismiss(animated: true, completion: nil)
    }
}
