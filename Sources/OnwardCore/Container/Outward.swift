/// A property wrapper that resolves a dependency declared with `@Inward`
/// from an `OnwardContainer`.
///
/// `@Outward` is the consumer-side counterpart of `@Inward` and is shaped after
/// SwiftUI's `@Environment`: you point it at a key path of
/// `OnwardContainer` and it returns the currently stored value (or the
/// declared default if no value has been set).
///
/// ```swift
/// extension OnwardContainer {
///     @Inward var apiClient: APIClient = DefaultAPIClient()
/// }
///
/// struct ProfileViewModel {
///     @Outward(\.apiClient) var apiClient: APIClient
/// }
/// ```
///
/// By default, `@Outward` reads from `OnwardContainer.shared`. Pass a
/// different container to the initializer when you need to scope the
/// resolution, for example inside unit tests.
@propertyWrapper
public struct Outward<Value> {
    private let keyPath: KeyPath<OnwardContainer, Value>
    private let container: OnwardContainer

    /// Creates an `@Outward` that resolves `keyPath` from the shared container.
    public init(_ keyPath: KeyPath<OnwardContainer, Value>) {
        self.keyPath = keyPath
        self.container = .shared
    }

    /// Creates an `@Outward` that resolves `keyPath` from the provided
    /// container. Use this when you need to isolate dependency resolution
    /// from the shared container — typically in tests.
    public init(_ keyPath: KeyPath<OnwardContainer, Value>, container: OnwardContainer) {
        self.keyPath = keyPath
        self.container = container
    }

    public var wrappedValue: Value {
        container[keyPath: keyPath]
    }
}
