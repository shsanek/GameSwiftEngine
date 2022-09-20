import Foundation

final class LoadMangerContext: ILoadMangerContext {
    class LazyContainer {
        let container: ObjectDecodableContainer
        var object: Any?

        init(container: ObjectDecodableContainer, object: Any? = nil) {
            self.container = container
            self.object = object
        }
    }

    private let dictionary: [ObjectLink: LazyContainer]
    private let controllers: [String: IAnyStorageElementController]

    init(
        dictionary: [ObjectLink : ObjectDecodableContainer],
        controllers: [String : IAnyStorageElementController]
    ) {
        var result = [ObjectLink: LazyContainer]()
        dictionary.forEach { (key, value) in
            result[key] = .init(container: value)
        }
        self.dictionary = result
        self.controllers = controllers
    }

    func load<Type>(_ link: ObjectLink) throws -> Type {
        try convert(try loadElement(link).object)
    }

    func loadElement(_ link: ObjectLink) throws -> StorageElement {
        guard let container = dictionary[link] else {
            throw StorageError.baseError("object with '\(link)' not found")
        }
        if let anyObject = container.object {
            return try convert(anyObject)
        }
        guard let controller = controllers[container.container.typeIdentifier] else {
            throw StorageError.baseError("controller for '\(container.container.typeIdentifier)' not found")
        }
        let model = try controller.decode(container: container.container.container)
        let object = try controller.makeObject(model: model, context: self)

        container.object = object
        return StorageElement(controller: controller, object: object, model: model)
    }
}
