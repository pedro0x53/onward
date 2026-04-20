import OnwardCore

/// Declares a new dependency entry on `OnwardContainer`.
///
/// Apply `@Inward` to a `var` inside an extension of `OnwardContainer`. The
/// macro generates:
///
/// 1. A private nested type conforming to `InwardKey` whose `defaultValue` is
///    produced from the variable's initializer expression.
/// 2. A computed `get`/`set` pair that reads and writes the value from the
///    container's keyed storage.
///
/// The result behaves like a SwiftUI `@Entry` declaration: dependencies have
/// type-safe access through `@Outward(\.entry)` and a sensible default when
/// nothing has been registered.
///
/// ```swift
/// extension OnwardContainer {
///     @Inward var apiClient: APIClient = DefaultAPIClient()
/// }
/// ```
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Inward() = #externalMacro(module: "OnwardGeneratorsMacros", type: "InwardMacro")
