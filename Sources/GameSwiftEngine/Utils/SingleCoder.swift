extension Decoder {
    public func decode<Type: Decodable>(_ type: Type.Type) throws -> Type {
        return try self.singleValueContainer().decode(Type.self)
    }
}

extension Encoder {
    public func encode<Type: Encodable>(_ value: Type) throws {
        var container = self.singleValueContainer()
        try container.encode(value)
    }
}
