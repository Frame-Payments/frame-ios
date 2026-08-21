import Foundation

/// Decodes an optional value, falling back to `nil` instead of throwing when the JSON holds
/// the wrong type or a malformed value.
///
/// Apply to any optional property on a model decoded from an API response so that one bad
/// field cannot fail the whole object:
///
/// ```swift
/// public struct Capability: Codable {
///     public let id: String                             // required — still throws if wrong
///     @Lenient public var disabledReason: String?       // wrong type -> nil
/// }
/// ```
///
/// Non-optional properties are deliberately left unwrapped: a required field with a bad value
/// still fails decoding, because a model missing it is not usable.
///
/// A missing key also yields `nil`, via the `decode(_:forKey:)` overload below.
///
/// Not usable with `URL` (or any type whose `Decodable` needs more than a single value):
/// `Value(from:)` fails for those and degrades to `nil` even for well-formed input. Wrap the
/// raw `String` instead and convert in a computed property.
///
/// Encoding is transparent — the wrapped value is written exactly as the bare property would be,
/// and `nil` is omitted rather than encoded as JSON `null`.
@propertyWrapper
public struct Lenient<Value> {
    /// The underlying value, or `nil` when the key was absent, null, or held the wrong type.
    public var wrappedValue: Value?

    /// Wraps an existing optional value, for use outside of decoding.
    /// - Parameter wrappedValue: The value to wrap.
    public init(wrappedValue: Value?) {
        self.wrappedValue = wrappedValue
    }
}

extension Lenient: Decodable where Value: Decodable {
    /// Decodes the wrapped value, degrading a type mismatch or malformed value to `nil`.
    /// - Parameter decoder: The decoder positioned at the property's value.
    public init(from decoder: Decoder) throws {
        // Reached only when the key is present. A type mismatch or malformed value degrades to nil.
        wrappedValue = try? Value(from: decoder)
    }
}

extension Lenient: Encodable where Value: Encodable {
    /// Encodes the wrapped value transparently, as the bare optional would encode.
    /// - Parameter encoder: The encoder to write into.
    public func encode(to encoder: Encoder) throws {
        // `encodeIfPresent` in the container overload below handles nil, so a value is present here.
        try wrappedValue?.encode(to: encoder)
    }
}

extension Lenient: Equatable where Value: Equatable {}
extension Lenient: Hashable where Value: Hashable {}
extension Lenient: Sendable where Value: Sendable {}

/// Lets a synthesized `init(from:)` treat a missing `@Lenient` key as `nil`.
public extension KeyedDecodingContainer {
    /// Returns `nil` rather than throwing when the key is absent or its value is `null`.
    ///
    /// The compiler routes synthesized `init(from:)` for a `@Lenient` property through this
    /// overload instead of the throwing `decode(_:forKey:)`, which is what lets a missing key
    /// behave the same as a bad one.
    func decode<Value: Decodable>(_ type: Lenient<Value>.Type, forKey key: Key) throws -> Lenient<Value> {
        // `decodeNil` distinguishes an explicit JSON null from a value that failed to decode.
        try decodeIfPresent(type, forKey: key) ?? Lenient(wrappedValue: nil)
    }
}

/// Keeps `@Lenient` encoding identical to a bare optional's.
public extension KeyedEncodingContainer {
    /// Omits the key entirely when the wrapped value is `nil`, matching how a bare optional encodes.
    mutating func encode<Value: Encodable>(_ value: Lenient<Value>, forKey key: Key) throws {
        try encodeIfPresent(value.wrappedValue, forKey: key)
    }
}
