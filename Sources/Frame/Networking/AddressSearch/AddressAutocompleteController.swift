//
//  AddressAutocompleteController.swift
//  Frame-iOS
//

import Foundation

/// Drives the suggestion list behind an address field.
///
/// Autocomplete never blocks manual entry. Every failure path — no token, Mapbox unreachable, an
/// empty result set — clears the suggestions and reports nothing, so a user who is typing simply
/// sees no list rather than an error.
@MainActor
public final class AddressAutocompleteController: ObservableObject {
    /// Suspends for a duration. Injected so tests need no real time.
    public typealias Sleeper = @Sendable (Duration) async throws -> Void
    /// Looks up suggestions for a query. Injected so tests need no networking.
    public typealias Search = @Sendable (_ query: String, _ countryCode: String?) async throws -> [AddressSuggestion]
    /// Resolves a suggestion into a full address.
    public typealias Retrieve = @Sendable (AddressSuggestion) async throws -> FrameObjects.BillingAddress

    /// The shortest query worth a request. Below this the list stays empty and nothing is sent.
    public static let minimumQueryLength = 3

    @Published public private(set) var suggestions: [AddressSuggestion] = []

    private let debounceInterval: Duration
    private let sleep: Sleeper
    private let search: Search
    private let retrieveAddress: Retrieve

    /// The in-flight lookup, cancelled whenever new input arrives so a fast typist sends one
    /// request rather than one per keystroke.
    private var searchTask: Task<Void, Never>?

    public init(
        debounceInterval: Duration = .milliseconds(300),
        sleep: Sleeper? = nil,
        search: Search? = nil,
        retrieve: Retrieve? = nil
    ) {
        self.debounceInterval = debounceInterval
        self.sleep = sleep ?? { try await Task.sleep(for: $0) }
        self.search = search ?? { query, country in
            try await AddressSearchService.shared.suggest(query: query, countryCode: country)
        }
        self.retrieveAddress = retrieve ?? { suggestion in
            try await AddressSearchService.shared.retrieve(suggestion: suggestion)
        }
    }

    /// Reacts to the user typing. Cancels any pending lookup, waits out the debounce, then
    /// searches — so only the last query in a burst reaches the network.
    public func queryChanged(_ query: String, countryCode: String?) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumQueryLength else {
            suggestions = []
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await self.sleep(self.debounceInterval)
            } catch {
                // Cancelled during the debounce: a newer keystroke owns the list now.
                return
            }

            guard !Task.isCancelled else { return }

            let found = (try? await self.search(trimmed, countryCode)) ?? []

            guard !Task.isCancelled else { return }
            self.suggestions = found
        }
    }

    /// Resolves a picked suggestion, or returns `nil` when it cannot be resolved.
    public func select(_ suggestion: AddressSuggestion) async -> FrameObjects.BillingAddress? {
        searchTask?.cancel()
        suggestions = []
        return try? await retrieveAddress(suggestion)
    }

    /// Clears the list without sending anything, for dismissing on blur.
    public func clear() {
        searchTask?.cancel()
        suggestions = []
    }
}
