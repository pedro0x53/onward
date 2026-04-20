import Foundation

/// A type-safe container for dependencies that can be consumed anywhere in
/// your app through the `@Outward` property wrapper.
///
/// `OnwardContainer` plays the same role that `EnvironmentValues` plays in
/// SwiftUI: it holds a mapping from `InwardKey` types to their resolved
/// values. Entries are declared by extending the container with the `@Inward`
/// macro, and consumed via `@Outward(\.keyPath)`.
///
/// ```swift
/// extension OnwardContainer {
///     @Inward var apiClient: APIClient = DefaultAPIClient()
/// }
///
/// struct Feature {
///     @Outward(\.apiClient) var apiClient: APIClient
/// }
/// ```
///
/// The shared singleton `OnwardContainer.shared` is the default resolution
/// point used by `@Outward`. You can override entries for testing or at
/// composition time by assigning through the keyed subscript:
///
/// ```swift
/// OnwardContainer.shared.apiClient = MockAPIClient()
/// ```
///
/// The container is safe to read and write from concurrent contexts.
public final class OnwardContainer: @unchecked Sendable {

    /// The shared container used by `@Outward` to resolve dependencies.
    public static let shared = OnwardContainer()

    private var storage: [ObjectIdentifier: Any] = [:]
    private let lock = NSLock()

    public init() {}

    /// Reads or writes the value associated with the given `InwardKey`.
    ///
    /// If no value has been written for `key`, the subscript returns
    /// `K.defaultValue`.
    public subscript<K: InwardKey>(_ key: K.Type) -> K.Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            if let value = storage[ObjectIdentifier(key)] as? K.Value {
                return value
            }
            return key.defaultValue
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storage[ObjectIdentifier(key)] = newValue
        }
    }

    /// Removes every explicitly assigned entry from the container, reverting
    /// each `@Inward` to its declared default value. Mostly useful for tests.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}
