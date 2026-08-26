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
    ///
    /// Two characters rather than three: a street number plus the first letter of the name is
    /// already enough for Mapbox to return useful results, and waiting for a third keystroke is
    /// the difference the user reads as the list being slow.
    public static let minimumQueryLength = 2

    /// The most suggestions the list will hold.
    ///
    /// Three rows is what fits on a phone between the address field and the form controls below
    /// it. Mapbox returns up to ten, and a list that long is clipped by the scrolling form it
    /// hangs over, leaving a half-drawn row the user cannot reach.
    public static let maximumSuggestions = 3

    @Published public private(set) var suggestions: [AddressSuggestion] = []

    private let debounceInterval: Duration
    private let sleep: Sleeper
    private let search: Search
    private let retrieveAddress: Retrieve

    /// The pending debounce, cancelled whenever new input arrives so a burst of keystrokes
    /// collapses into one request. Only the wait is cancelled — a request that already reached
    /// the network is left to finish, since killing it is what made the list wait for a pause
    /// in typing before it could ever appear.
    private var debounceTask: Task<Void, Never>?

    /// Counts queries so a slow response for an earlier one cannot overwrite the list with
    /// results for text the user has already moved past. Requests can complete out of order.
    private var latestQueryID = 0

    public init(
        debounceInterval: Duration = .milliseconds(80),
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

    /// Reacts to the user typing: waits out a short debounce, then searches.
    ///
    /// A new keystroke cancels only the pending wait, never a request already in flight. Results
    /// therefore arrive while the user is still typing rather than after they stop, and a
    /// response is applied only when it is for the most recent query — so an earlier lookup that
    /// resolves late is discarded instead of replacing newer results.
    public func queryChanged(_ query: String, countryCode: String?) {
        debounceTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumQueryLength else {
            latestQueryID += 1
            suggestions = []
            return
        }

        latestQueryID += 1
        let queryID = latestQueryID

        debounceTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await self.sleep(self.debounceInterval)
            } catch {
                // Cancelled during the debounce: a newer keystroke owns the list now.
                return
            }

            guard !Task.isCancelled else { return }

            // Run the request outside this task's cancellation scope. `URLSession.data(for:)`
            // is cancellation-aware, so leaving it here would let the next keystroke — which
            // cancels this task — kill a request that had already reached the network. That is
            // what forced the user to stop typing before any list could appear.
            let search = self.search
            let found = await Task.detached {
                (try? await search(trimmed, countryCode)) ?? []
            }.value

            // Apply only if no newer query has been issued while this one was in flight.
            guard queryID == self.latestQueryID else { return }
            self.suggestions = Array(found.prefix(Self.maximumSuggestions))
        }
    }

    /// Resolves a picked suggestion, or returns `nil` when it cannot be resolved.
    public func select(_ suggestion: AddressSuggestion) async -> FrameObjects.BillingAddress? {
        debounceTask?.cancel()
        // Bumping the ID retires any in-flight search, so a response that lands after the pick
        // cannot repopulate the list the user has just dismissed.
        latestQueryID += 1
        suggestions = []
        return try? await retrieveAddress(suggestion)
    }

    /// Clears the list without sending anything, for dismissing on blur.
    public func clear() {
        debounceTask?.cancel()
        latestQueryID += 1
        suggestions = []
    }
}
