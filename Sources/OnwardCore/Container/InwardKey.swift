/// A protocol that identifies a dependency entry stored in an `OnwardContainer`.
///
/// Types conforming to `InwardKey` act as unique, type-safe keys that look up a
/// value of type `Value` inside an `OnwardContainer`. When no value has been
/// explicitly assigned, `defaultValue` is returned instead.
///
/// You typically do not conform to this protocol by hand. Use the `@Inward`
/// macro on an `OnwardContainer` extension to generate the conforming key
/// automatically, in the same spirit of SwiftUI's `EnvironmentKey`.
///
/// ```swift
/// extension OnwardContainer {
///     @Inward var apiClient: APIClient = DefaultAPIClient()
/// }
/// ```
public protocol InwardKey: Sendable {
    associatedtype Value: Sendable
    static var wrappedValue: Value { get set }
}
