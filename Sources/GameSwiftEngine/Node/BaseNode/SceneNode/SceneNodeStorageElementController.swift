extension SceneNode {
    public struct Model: Codable {
        public var node: Node.NodeModel = .init()

        public init() { }
    }
}

public struct SceneNodeStorageElementController: IStorageElementController {
    public var typeIdentifier: String { "SceneNode" }

    public func makeDefaultModel() throws -> SceneNode.Model {
        SceneNode.Model()
    }

    public func makeObject(model: SceneNode.Model, context: ILoadMangerContext) throws -> SceneNode {
        let node = SceneNode()
        try model.node.load(object: node, context: context)
        return node
    }

    public func save(
        model: inout SceneNode.Model,
        object: SceneNode,
        context: ISaveMangerContext,
        shouldModelUpdate: Bool
    ) throws {
        if shouldModelUpdate {
            try model.node.update(with: object)
        }
        try model.node.saveSubobjects(object, context: context)
    }
}
