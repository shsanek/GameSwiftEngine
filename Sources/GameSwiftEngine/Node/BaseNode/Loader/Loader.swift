import Foundation

public protocol ITypeIdentifieble: AnyObject {
    var typeIdentifier: String { get }
}

public protocol IStorageElementController {
    associatedtype Model: Codable
    associatedtype Object

    var typeIdentifier: String { get }

    func makeDefaultModel() throws -> Model

    func makeObject(model: Model, context: ILoadMangerContext) throws -> Object
    func save(model: inout Model, object: Object, context: ISaveMangerContext, shouldModelUpdate: Bool) throws
}

public protocol IAnyStorageElementController {
    var typeIdentifier: String { get }

    func makeDefaultModel() throws -> Any
    func makeObject(model: Any, context: ILoadMangerContext) throws -> Any
    func save(model: inout Any, object: Any, context: ISaveMangerContext, shouldModelUpdate: Bool) throws
    func encode(model: Any, encoder: Encoder) throws
    func decode(container: SingleValueDecodingContainer) throws -> Any
}

public protocol ILoadMangerContext {
    func load<Type>(_ link: ObjectLink) throws -> Type
}

public protocol ISaveMangerContext {
    func save(_ link: ObjectLink, object: ITypeIdentifieble) throws
}
