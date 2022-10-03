import simd

extension LightNode {
    public struct Model: Codable {
        public var node: Node.NodeModel = .init()
        public var isShadow: Bool = false
        public var color: vector_float3 = .zero
        public var power: GEFloat = 0
        public var step: GEFloat? = 0
        public var angle: GEFloat? = .pi
        public var attenuationAngle: GEFloat? = 0
        public var shadowSkipFrame: Int = 0
        public init() { }
    }
}

public struct LightNodeStorageElementController: IStorageElementController {
    public var typeIdentifier: String { "LightNode" }

    public func makeDefaultModel() throws -> LightNode.Model {
        LightNode.Model()
    }

    public func makeObject(model: LightNode.Model, context: ILoadMangerContext) throws -> LightNode {
        let node = LightNode()
        try model.node.load(object: node, context: context)
        node.angle = model.angle
        node.isShadow = model.isShadow
        node.color = model.color
        node.power = model.power
        node.step = model.step
        node.attenuationAngle = model.attenuationAngle
        node.shadowSkipFrame = model.shadowSkipFrame
        return node
    }

    public func save(
        model: inout LightNode.Model,
        object: LightNode,
        context: ISaveMangerContext,
        shouldModelUpdate: Bool
    ) throws {
        if shouldModelUpdate {
            try model.node.update(with: object)
            model.angle = object.angle
            model.isShadow = object.isShadow
            model.color = object.color
            model.power = object.power
            model.step = object.step
            model.attenuationAngle = object.attenuationAngle
            model.shadowSkipFrame = object.shadowSkipFrame
        }
        try model.node.saveSubobjects(object, context: context)
    }
}
