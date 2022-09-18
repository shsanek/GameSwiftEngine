public final class RenderAttributes {
    private var values: [String: Any] = [:]

    public func set<Value>(_ key: RenderAttributesKey<Value>, value: Value) {
        values[key.key] = value
    }

    func getValue<Value>(_ key: RenderAttributesKey<Value>) -> Value? {
        return values[key.key] as? Value
    }

    func getValue(_ key: RenderAttributesKey<Bool>) -> Bool {
        return (values[key.key] as? Bool) ?? false
    }

    public init() {}
}

public struct RenderAttributesKey<TypeValue> {
    let key: String

    init(key: String, type: TypeValue.Type) {
        self.key = key
    }
}

extension RenderAttributesKey {
    static func make<TypeValue>(key: String, type: TypeValue.Type) -> RenderAttributesKey<TypeValue> {
        RenderAttributesKey<TypeValue>(key: key, type: type)
    }
}
