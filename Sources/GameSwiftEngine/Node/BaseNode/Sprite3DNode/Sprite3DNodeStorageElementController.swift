extension Sprite3DNode{
    public struct Model: Codable {
        public var textureName: String? = nil
        public var geometry: Sprite3DNodeGeometrySource = .plane(.init(width: 1, height: 1))
        public var node: Node.NodeModel = .init()

        public init() { }
    }
}

public struct Sprite3DNodeStorageElementController: IStorageElementController {
    public var typeIdentifier: String { "Sprite3DNode" }

    public func makeDefaultModel() throws -> Sprite3DNode.Model {
        Sprite3DNode.Model()
    }

    public func makeObject(model: Sprite3DNode.Model, context: ILoadMangerContext) throws -> Sprite3DNode {
        let node = Sprite3DNode(
            geometry: model.geometry,
            texture: Texture.load(in: model.textureName)
        )
        try model.node.load(object: node, context: context)

        return node
    }

    public func save(
        model: inout Sprite3DNode.Model,
        object: Sprite3DNode,
        context: ISaveMangerContext,
        shouldModelUpdate: Bool
    ) throws {
        if shouldModelUpdate {
            try model.node.update(with: object)
            model.geometry = object.getSprite3DNodeGeometrySource()
            model.textureName = (object.texture as? ISourceTexture)?.sourcePath
        }
        try model.node.saveSubobjects(object, context: context)
    }
}
