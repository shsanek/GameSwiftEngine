import Foundation

final class SaveMangerContext: ISaveMangerContext {
    struct Container {
        let model: Any
        let typeIdentifier: String
    }

    private(set) var dictionary: [ObjectLink: ObjectEncodableContainer] = [:]
    private let controllers: [String: IAnyStorageElementController]
    private let shouldModelUpdate: Bool

    init(
        controllers: [String : IAnyStorageElementController],
        shouldModelUpdate: Bool
    ) {
        self.controllers = controllers
        self.shouldModelUpdate = shouldModelUpdate
    }

    func save(_ link: ObjectLink, object: ITypeIdentifieble) throws {
        guard dictionary[link] != nil else {
            return
        }
        guard let controller = controllers[object.typeIdentifier] else {
            throw StorageError.baseError("controller for '\(object.typeIdentifier)' not found")
        }
        var model = try controller.makeDefaultModel()
        try controller.save(model: &model, object: object, context: self, shouldModelUpdate: shouldModelUpdate)
        dictionary[link] = .init(typeIdentifier: object.typeIdentifier, { encoder in
            try controller.encode(model: model, encoder: encoder)
        })
    }
}
