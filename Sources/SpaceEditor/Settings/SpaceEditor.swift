import SwiftUI
import GameSwiftEngine

public protocol ISettingController {
    associatedtype Model
    associatedtype Object

    typealias UpdateHandler = (_ model: inout Model, _ object: inout Object) throws -> Void

    func makeView(model: Model, _ updateRequest: @escaping ((@escaping UpdateHandler) throws -> Void)) throws -> AnyView
}

public protocol IAnySettingController {
    typealias UpdateHandler = (_ model: inout Any, _ object: inout Any) throws -> Void

    func makeView(model: Any, _ updateRequest: @escaping ((@escaping UpdateHandler) throws -> Void)) throws -> AnyView
}

public final class AnySettingController<Controller: ISettingController> {
    private let controller: Controller

    init(controller: Controller) {
        self.controller = controller
    }

    func makeView(
        model: Any,
        _ updateRequest: @escaping ((@escaping IAnySettingController.UpdateHandler) throws -> Void)
    ) throws -> AnyView {
        let model = try convert(model) as Controller.Model
        return try controller.makeView(model: model, { (handler) in
            try updateRequest { model, object in
                var tmpModel = try convert(model) as Controller.Model
                var tmpObject = try convert(object) as Controller.Object

                try handler(&tmpModel, &tmpObject)

                model = tmpModel
                object = tmpObject
            }
        })
    }
}

public protocol IBaseNodeChangeable {
    var node: Node.NodeModel { get set }
}

extension Node.Model: IBaseNodeChangeable { }

public struct BaseNodeController: ISettingController {
    public typealias Model = IBaseNodeChangeable
    public typealias Object = Node

    public func makeView(
        model: Model,
        _ updateRequest: @escaping ((@escaping UpdateHandler) throws -> Void)
    ) throws -> AnyView {
        AnyView(Text("empty"))
    }
}

public protocol IObjectManager {
    func register<
        StorageController: IStorageElementController
    >(
        storageController: StorageController,
        settingControllers: [IAnySettingController]
    )
}

public final class Project {
    func addSubobject() {}
}
