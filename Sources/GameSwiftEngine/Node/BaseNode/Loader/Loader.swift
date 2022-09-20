public struct ModalDecoderContainer: Decodable {
    private struct DecodResolver: Decodable {
        let container: SingleValueDecodingContainer

        init(from decoder: Decoder) throws {
            self.container = try decoder.singleValueContainer()
        }
    }

    let typeIdentifier: String
    let container: SingleValueDecodingContainer

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.container = try container.decode(DecodResolver.self, forKey: .object).container
        self.typeIdentifier = try container.decode(String.self, forKey: .typeIdentifier)
    }

    public func decode<Type>(_ factory: IDecodableModelFactory, type: Type.Type) throws -> Type {
        return try factory.decode(self) as Type
    }

    enum CodingKeys: String, CodingKey {
        case typeIdentifier
        case object
    }
}

public enum CodableError: Error {
    case error(_ message: String)
}

public protocol IDecodableModelFactory {
    func decode<ResultType>(
        _ container: ModalDecoderContainer
    ) throws -> ResultType
}

extension KeyedDecodingContainer {
    public func decode<T>(
        from factory: IDecodableModelFactory,
        type: T.Type = T.self,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> T {
        let container = try decode(ModalDecoderContainer.self, forKey: key)
        return try factory.decode(container)
    }

    public func decode<T>(
        from factory: IDecodableModelFactory,
        type: T.Type = T.self,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> [T] {
        let containers = try decode([ModalDecoderContainer].self, forKey: key)
        return try containers.map { try factory.decode($0) }
    }

    public func decodeSafe<T>(
        from factory: IDecodableModelFactory,
        type: T.Type = T.self,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> [T] {
        let containers = try decode([ModalDecoderContainer].self, forKey: key)
        return containers.compactMap { try? factory.decode($0) }
    }
}

extension SingleValueDecodingContainer {
    public func decode<T>(
        from factory: IDecodableModelFactory,
        type: T.Type = T.self
    ) throws -> T {
        let container = try decode(ModalDecoderContainer.self)
        return try factory.decode(container)
    }

    public func decode<T>(
        from factory: IDecodableModelFactory,
        type: T.Type = T.self
    ) throws -> [T] {
        let containers = try decode([ModalDecoderContainer].self)
        return try containers.map { try factory.decode($0) }
    }

    public func decodeSafe<T>(
        from factory: IDecodableModelFactory,
        type: T.Type = T.self
    ) throws -> [T] {
        let containers = try decode([ModalDecoderContainer].self)
        return containers.compactMap { try? factory.decode($0) }
    }
}

public final class CodableModelFactory: IDecodableModelFactory {
    private var makers = [String: (SingleValueDecodingContainer) throws -> Any]()

    public init() {
    }

    public func register<Type>(
        typeIdentifier: String,
        maker: @escaping ((decoder: SingleValueDecodingContainer, factory: IDecodableModelFactory)) throws -> Type
    ) throws {
        guard makers[typeIdentifier] == nil else {
            throw CodableError.error("'\(typeIdentifier)' alredy register")
        }
        makers[typeIdentifier] = { [weak self] decoder in
            guard let self = self else {
                throw CodableError.error("unritain factory")
            }
            return try maker((decoder: decoder, factory: self))
        }
    }

    public func register<TypeCodable: ModelCodable>(_ type: TypeCodable.Type) throws {
        try register(
            typeIdentifier: TypeCodable.typeIdentifier,
            maker: TypeCodable.init
        )
    }

    public func decode<ResultType>(
        _ container: ModalDecoderContainer
    ) throws -> ResultType {
        guard let maker = makers[container.typeIdentifier] else {
            throw CodableError.error("maker with key: '\(container.typeIdentifier)' not found")
        }
        let value = try maker(container.container)
        guard let result = value as? ResultType else {
            throw CodableError.error("'\(value.self)' is not '\(ResultType.self)'")
        }
        return result
    }
}

public protocol ModelCodable: Encodable {
    static var typeIdentifier: String { get }

    init(
        container: SingleValueDecodingContainer,
        factory: IDecodableModelFactory
    ) throws
}

extension ModelCodable {
    public static var typeIdentifier: String {
        return "\(Self.self)"
    }
}

public struct ModalEncodableContainer<Container: Encodable>: Encodable {
    public let typeIdentifier: String
    public let object: Container

    public init(typeIdentifier: String, object: Container) {
        self.typeIdentifier = typeIdentifier
        self.object = object
    }
}

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

protocol ModelStorage {
    func load<Type>(_ link: ObjectLink) throws -> Type
}

import simd

extension matrix_float4x4: Codable {
    struct Model: Codable {
        let a: vector_float4
        let b: vector_float4
        let c: vector_float4
        let d: vector_float4
    }

    public init(from decoder: Decoder) throws {
        let model = try decoder.decode(Model.self)
        self.init(columns: (model.a, model.b, model.c, model.d))
    }

    public func encode(to encoder: Encoder) throws {
        let model = Model(a: columns.0, b: columns.1, c: columns.2, d: columns.3)
        try encoder.encode(model)
    }
}

public struct ObjectLink: Codable {
    let link: String

    public init(_ object: AnyObject) {
        link = "\(ObjectIdentifier(object))"
    }
}
