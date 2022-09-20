import Foundation

public final class StorageManager {
    private var controllers: [String: IAnyStorageElementController] = [:]

    public func register<T: IStorageElementController>(controller: T) {
        let anyController = AnyStorageElementController(controller: controller)
        controllers[anyController.typeIdentifier] = anyController
    }

    public func load(data: Data, decoder: IDecoder = JSONDecoder()) throws -> [StorageElement] {
        let dictionary = try decoder.decode([ObjectLink : ObjectDecodableContainer].self, from: data)
        let context = LoadMangerContext(dictionary: dictionary, controllers: controllers)
        var result: [StorageElement] = []
        try dictionary.forEach { (key: ObjectLink, value: ObjectDecodableContainer) in
            result.append(try context.loadElement(key))
        }
        return result
    }

    public func save(objects: [ITypeIdentifieble], shouldModelUpdate: Bool = false, encoder: IEncoder = JSONEncoder()) throws -> Data {
        let context = SaveMangerContext(controllers: controllers, shouldModelUpdate: shouldModelUpdate)
        try objects.forEach { (object: ITypeIdentifieble) in
            try context.save(ObjectLink(object), object: object)
        }
        return try encoder.encode(context.dictionary)
    }
}
