//
//  AddressAutocompleteField.swift
//  Frame-iOS
//

import SwiftUI

/// An address line 1 field that offers suggestions as the user types.
///
/// The field is a plain ``ValidatedTextField``, so typing an address by hand works exactly as it
/// does without autocomplete. Suggestions are drawn in an overlay below it and appear only while
/// the field is focused and the lookup returned something.
public struct AddressAutocompleteField: View {
    @Environment(\.frameTheme) private var theme

    private let prompt: String
    @Binding private var text: String
    @Binding private var error: String?
    private let countryCode: String?
    private let inlineError: Bool
    private let onSelect: (FrameObjects.BillingAddress) -> Void

    @StateObject private var controller: AddressAutocompleteController
    @FocusState private var isFocused: Bool

    /// Creates an address field backed by autocomplete.
    ///
    /// - Parameters:
    ///   - prompt: Placeholder text shown inside the field when it is empty.
    ///   - text: Two-way binding to the address line 1 value.
    ///   - error: Two-way binding to an optional validation error message.
    ///   - countryCode: ISO 3166-1 alpha-2 code the suggestions are restricted to, so a form
    ///     locked to one country does not surface addresses from another.
    ///   - inlineError: When `true`, the error label sits beside the field rather than below it.
    ///   - controller: Drives the suggestion list. Injected in tests; the default talks to Mapbox.
    ///   - onSelect: Called with the full address when the user picks a suggestion.
    public init(prompt: String,
                text: Binding<String>,
                error: Binding<String?>,
                countryCode: String?,
                inlineError: Bool = false,
                controller: AddressAutocompleteController? = nil,
                onSelect: @escaping (FrameObjects.BillingAddress) -> Void) {
        self.prompt = prompt
        self._text = text
        self._error = error
        self.countryCode = countryCode
        self.inlineError = inlineError
        self.onSelect = onSelect
        self._controller = StateObject(wrappedValue: controller ?? AddressAutocompleteController())
    }

    /// The view hierarchy that renders the field and, while it is focused, its suggestion list.
    public var body: some View {
        ValidatedTextField(prompt: prompt,
                           text: $text,
                           error: $error,
                           textContentType: .streetAddressLine1,
                           inlineError: inlineError,
                           focused: $isFocused)
            .onChange(of: text) { _, newValue in
                // A selection writes the field, so only react while the user is the one typing.
                guard isFocused else { return }
                controller.queryChanged(newValue, countryCode: countryCode)
            }
            .onChange(of: isFocused) { _, focused in
                if !focused { controller.clear() }
            }
            .overlay(alignment: .topLeading) {
                if isFocused, !controller.suggestions.isEmpty {
                    suggestionList
                        // Offset by the field's own height so the list hangs below it without
                        // taking part in the form's layout, which both billing forms size by hand.
                        .offset(y: 49.0)
                }
            }
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(controller.suggestions) { suggestion in
                Button {
                    select(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(theme.fonts.body)
                            .foregroundColor(theme.colors.textPrimary)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                if suggestion.id != controller.suggestions.last?.id {
                    Divider()
                }
            }
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.medium))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke)
        )
        .shadow(radius: 4)
        .zIndex(1)
    }

    private func select(_ suggestion: AddressSuggestion) {
        Task {
            guard let address = await controller.select(suggestion) else { return }
            onSelect(address)
            isFocused = false
        }
    }
}
