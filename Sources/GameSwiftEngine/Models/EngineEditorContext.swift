import ObjectEditor

extension OMContext {
    public static let swiftGameEngineContext: OMContext = {
        let context = OMContext()
        do {
            try context.registerObjects([
                .make(name: "Node", { Node.init() }),
                .make(name: "Object3D", { Object3DNode.init() }),
                .make(name: "Light", { LightNode() })
            ])
            try context.registerModifications([
                .make(name: "Base", { NodeBaseModification.init() }),
                .make(name: "Object3D", { Object3DNodeModification.init() }),
                .make(name: "Light", { NodeLightModification.init() })
            ])
        }
        catch {
            print(error)
        }
        return context
    }()
}
