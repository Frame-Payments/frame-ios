//
//  BankAccountViewModel.swift
//  Frame-iOS
//

import SwiftUI
import Frame

@MainActor
public final class BankAccountViewModel: ObservableObject {
    public enum Field: Hashable, Sendable {
        case routing, account
    }

    @Published public var account: FrameObjects.BankAccount
    @Published public var errors: [Field: String] = [:]

    public init(account: FrameObjects.BankAccount = FrameObjects.BankAccount(accountType: .checking)) {
        self.account = account
    }

    @discardableResult
    public func validate() -> Bool {
        var next: [Field: String] = [:]
        if let err = Validators.validateRoutingNumberUS(account.routingNumber ?? "") {
            next[.routing] = err
        }
        if let err = Validators.validateAccountNumberUS(account.accountNumber ?? "") {
            next[.account] = err
        }
        errors = next
        return next.isEmpty
    }

    public func errorBinding(_ field: Field) -> Binding<String?> {
        Binding(
            get: { [weak self] in self?.errors[field] },
            set: { [weak self] in self?.errors[field] = $0 }
        )
    }
}
