//
//  BankAccountViewModel.swift
//  Frame-iOS
//

import SwiftUI
import Frame

/// View model that manages user input and validation for a bank account onboarding form.
///
/// Bind this object to a SwiftUI view to collect and validate US routing and account numbers
/// before submitting a ``FrameObjects/BankAccount`` to the Frame SDK.
@MainActor
public final class BankAccountViewModel: ObservableObject {
    /// Identifies a focusable input field in the bank account form.
    public enum Field: Hashable, Sendable {
        /// The ABA routing number field.
        case routing
        /// The bank account number field.
        case account
    }

    /// The bank account model being edited.
    @Published public var account: FrameObjects.BankAccount
    /// Validation error messages keyed by the field that failed.
    @Published public var errors: [Field: String] = [:]

    /// Creates a new view model, optionally seeded with an existing bank account.
    ///
    /// - Parameter account: The bank account to pre-populate the form with.
    ///   Defaults to a new checking account with no values set.
    public init(account: FrameObjects.BankAccount = FrameObjects.BankAccount(accountType: .checking)) {
        self.account = account
    }

    /// Validates the routing and account number fields and updates ``errors``.
    ///
    /// - Returns: `true` when all fields are valid; `false` if any validation errors were found.
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

    /// Returns a two-way binding to the error message for the given field.
    ///
    /// - Parameter field: The field whose error binding is requested.
    /// - Returns: A `Binding<String?>` that reads and writes the error entry in ``errors``.
    public func errorBinding(_ field: Field) -> Binding<String?> {
        Binding(
            get: { [weak self] in self?.errors[field] },
            set: { [weak self] in self?.errors[field] = $0 }
        )
    }
}
