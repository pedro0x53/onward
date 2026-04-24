import Foundation

public protocol OnwardContainerSchema: Sendable, AnyObject {
    static var container: Self { get }

    init()

    func inject<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value)
    func eject<Value>(_ keyPath: KeyPath<Self, Value>) -> Value
}

public extension OnwardContainerSchema {
    subscript<K: InwardKey>(_ key: K.Type) -> K.Value {
        get {
            DispatchQueue.onward.sync { return key.wrappedValue }
        }
        set {
            DispatchQueue.onward.async(flags: .barrier) {
                key.wrappedValue = newValue
            }
        }
    }

    func inject<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) {
        var instance = self
        instance[keyPath: keyPath] = value
    }

    func eject<Value>(_ keyPath: KeyPath<Self, Value>) -> Value {
        self[keyPath: keyPath]
    }

    static subscript<K: InwardKey>(_ key: K.Type) -> K.Value {
        get {
            DispatchQueue.onward.sync { return key.wrappedValue }
        }
        set {
            DispatchQueue.onward.async(flags: .barrier) {
                key.wrappedValue = newValue
            }
        }
    }

    static func inject<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) {
        var instance = Self()
        instance[keyPath: keyPath] = value
    }

    static func eject<Value>(_ keyPath: KeyPath<Self, Value>) -> Value {
        Self()[keyPath: keyPath]
    }
}

extension DispatchQueue {
    static let onward: DispatchQueue = .init(label: "studion.x53.onward.container", attributes: .concurrent)
}
