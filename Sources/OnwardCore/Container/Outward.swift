@propertyWrapper
public struct Outward<Container, Value> where Container: OnwardContainerSchema {
    private let keyPath: KeyPath<Container, Value>
    private let container: Container

    public init(
        _ keyPath: KeyPath<OnwardContainer, Value>
    ) where Container == OnwardContainer {
        self.keyPath = keyPath
        self.container = OnwardContainer()
    }

    public init(
        _ container: Container,
        _ keyPath: KeyPath<Container, Value>
    ) {
        self.keyPath = keyPath
        self.container = container
    }

    public init(
        _ container: Container.Type,
        _ keyPath: KeyPath<Container, Value>
    ) {
        self.keyPath = keyPath
        self.container = container.init()c
    }

    public var wrappedValue: Value {
        container[keyPath: keyPath]
    }
}
