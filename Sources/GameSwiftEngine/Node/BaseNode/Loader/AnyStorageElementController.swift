import Foundation

struct AnyStorageElementController<Controller: IStorageElementController>: IAnyStorageElementController {
    var typeIdentifier: String

    private let controller: Controller

    init(
        controller: Controller
    ) {
        self.controller = controller
        typeIdentifier = controller.typeIdentifier
    }

    func makeDefaultModel() throws -> Any {
        try controller.makeDefaultModel()
    }

    func makeObject(model: Any, context: ILoadMangerContext) throws -> Any {
        let model: Controller.Model = try convert(model)
        return try controller.makeObject(model: model, context: context)
    }

    func save(model: inout Any, object: Any, context: ISaveMangerContext, shouldModelUpdate: Bool) throws {
        var tmpModel: Controller.Model = try convert(model)
        let object: Controller.Object = try convert(object)
        try controller.save(model: &tmpModel, object: object, context: context, shouldModelUpdate: shouldModelUpdate)
        model = tmpModel
    }

    func encode(model: Any, encoder: Encoder) throws {
        let model: Controller.Model = try convert(model)
        try encoder.encode(model)
    }

    func decode(container: SingleValueDecodingContainer) throws -> Any {
        try container.decode(Controller.Model.self)
    }
}
