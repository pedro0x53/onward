import Volt

// MARK: - OnwardContainer

/// The application-level dependency container for Onward.
///
/// `OnwardContainer` is the single place where injectable dependencies live.
/// It is built on top of Volt's `@Charger` infrastructure, which provides
/// thread-safe, keyed storage with default values.
///
/// ## Registering dependencies
///
/// Declare dependencies by extending `OnwardContainer` and annotating each
/// stored `var` with ``Inward``. The macro generates a private key type and a
/// computed `get`/`set` pair backed by the container's storage:
///
/// ```swift
/// extension OnwardContainer {
///     @Inward var apiClient: APIClient = DefaultAPIClient()
///     @Inward var analyticsService: Analytics = FirebaseAnalytics()
/// }
/// ```
///
/// ## Resolving dependencies
///
/// Use ``Outward`` wherever you need a dependency — typically as a stored
/// property of an ``Interactor``:
///
/// ```swift
/// @Interactor
/// final class TodoInteractor {
///     @Outward(\.apiClient) var apiClient: APIClient
/// }
/// ```
///
/// ## Overriding for testing
///
/// Write directly to the container to swap implementations without a DI
/// framework or manual injection:
///
/// ```swift
/// OnwardContainer.shared.apiClient = MockAPIClient()
/// ```
@Charger
public final class OnwardContainer {}

// MARK: - Inward

/// Declares a dependency entry on ``OnwardContainer``.
///
/// Apply `@Inward` to a `var` inside an extension of `OnwardContainer`.
/// The macro generates:
///
/// 1. A private key type that uniquely identifies the dependency.
/// 2. A computed `get`/`set` pair backed by the container's thread-safe storage.
///
/// The annotated variable's initializer expression becomes the **default
/// value** returned when no override has been registered.
///
/// ```swift
/// extension OnwardContainer {
///     @Inward var apiClient: APIClient = DefaultAPIClient()
/// }
/// ```
///
/// Resolve the dependency anywhere with ``Outward``:
///
/// ```swift
/// @Outward(\.apiClient) var apiClient: APIClient
/// ```
///
/// > Note: `@Inward` is backed by Volt's `@Charge` macro and shares its
/// > storage semantics.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Inward() = #externalMacro(module: "VoltMacros", type: "ChargeMacro")

// MARK: - Outward

/// A property wrapper that resolves a dependency from ``OnwardContainer``.
///
/// `Outward` is a typealias for Volt's `Discharge` property wrapper, bound
/// to ``OnwardContainer``. It reads the value at the given key path each time
/// `wrappedValue` is accessed, so it always reflects the current registration.
///
/// ```swift
/// @Interactor
/// final class TodoInteractor {
///     @Outward(\.apiClient) var apiClient: APIClient
///     @Outward(\.analyticsService) var analytics: Analytics
/// }
/// ```
///
/// You can also override a dependency at runtime (useful in tests) by writing
/// directly to the container:
///
/// ```swift
/// OnwardContainer.shared.apiClient = MockAPIClient()
/// ```
public typealias Outward<Value> = Discharge<OnwardContainer, Value>

public extension Discharge {
    /// Creates an `Outward` wrapper that reads from ``OnwardContainer`` at
    /// the given key path.
    ///
    /// This convenience initializer lets you write `@Outward(\.apiClient)`
    /// without spelling out `OnwardContainer` explicitly.
    ///
    /// - Parameter keyPath: A key path into ``OnwardContainer`` for the
    ///   dependency declared with ``Inward``.
    init(_ keyPath: KeyPath<OnwardContainer, Value>) where Charger == OnwardContainer {
        self.init(OnwardContainer.self, keyPath)
    }
}
