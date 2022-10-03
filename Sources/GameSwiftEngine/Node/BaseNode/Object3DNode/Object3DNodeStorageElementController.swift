extension Object3DNode {
    public struct Model: Codable {
        public var textureName: String? = nil
        public var fileName: String? = nil
        public var node: Node.NodeModel = .init()

        public init() { }
    }
}

public struct Object3DNodeStorageElementController: IStorageElementController {
    public var typeIdentifier: String { "Object3DNode" }

    public func makeDefaultModel() throws -> Object3DNode.Model {
        Object3DNode.Model()
    }

    public func makeObject(model: Object3DNode.Model, context: ILoadMangerContext) throws -> Object3DNode {
        let node = Object3DNode(
            source: model.fileName.flatMap { .iqe($0) } ?? .empty,
            texture: Texture.load(in: model.textureName)
        )
        try model.node.load(object: node, context: context)

        return node
    }

    public func save(
        model: inout Object3DNode.Model,
        object: Object3DNode,
        context: ISaveMangerContext,
        shouldModelUpdate: Bool
    ) throws {
        if shouldModelUpdate {
            try model.node.update(with: object)
            if case .iqe(let file) = object.geometry {
                model.fileName = file
            } else {
                model.fileName = nil
            }
            model.textureName = (object.texture as? ISourceTexture)?.sourcePath
        }
        try model.node.saveSubobjects(object, context: context)
    }
}

