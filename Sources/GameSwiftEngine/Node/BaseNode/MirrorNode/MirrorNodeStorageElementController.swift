extension MirrorNode {
    public struct Model: Codable {
        public var node: Node.NodeModel = .init()

        public init() { }
    }
}

public struct MirrorNodeStorageElementController: IStorageElementController {
    public var typeIdentifier: String { "MirrorNode" }

    public func makeDefaultModel() throws -> MirrorNode.Model {
        MirrorNode.Model()
    }

    public func makeObject(model: MirrorNode.Model, context: ILoadMangerContext) throws -> MirrorNode {
        let node = MirrorNode()
        try model.node.load(object: node, context: context)
        return node
    }

    public func save(
        model: inout MirrorNode.Model,
        object: MirrorNode,
        context: ISaveMangerContext,
        shouldModelUpdate: Bool
    ) throws {
        if shouldModelUpdate {
            try model.node.update(with: object)
        }
        try model.node.saveSubobjects(object, context: context)
    }
}
