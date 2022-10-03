extension CameraNode {
    public struct Model: Codable {
        public var node: Node.NodeModel = .init()
        public var isActive: Bool = false
        public init() { }
    }
}

public struct CameraNodeStorageElementController: IStorageElementController {
    public var typeIdentifier: String { "CameraNode" }

    public func makeDefaultModel() throws -> CameraNode.Model {
        CameraNode.Model()
    }

    public func makeObject(model: CameraNode.Model, context: ILoadMangerContext) throws -> CameraNode {
        let node = CameraNode()
        try model.node.load(object: node, context: context)
        node.isActive = model.isActive
        return node
    }

    public func save(
        model: inout CameraNode.Model,
        object: CameraNode,
        context: ISaveMangerContext,
        shouldModelUpdate: Bool
    ) throws {
        if shouldModelUpdate {
            try model.node.update(with: object)
            model.isActive = object.isActive
        }
        try model.node.saveSubobjects(object, context: context)
    }
}
