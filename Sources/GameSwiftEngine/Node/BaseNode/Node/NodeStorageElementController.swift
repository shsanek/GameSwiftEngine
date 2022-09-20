public struct NodeStorageElementController: IStorageElementController {
    public var typeIdentifier: String { "Node" }

    public func makeDefaultModel() throws -> Node.Model {
        Node.Model()
    }

    public func makeObject(model: Node.Model, context: ILoadMangerContext) throws -> Node {
        let node = Node()
        try model.load(object: node, context: context)
        return node
    }

    public func save(model: inout Node.Model, object: Node, context: ISaveMangerContext, shouldModelUpdate: Bool) throws {
        if shouldModelUpdate {
            try model.update(with: object)
        }
        try model.saveSubobjects(object, context: context)
    }
}
