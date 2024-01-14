import ObjectEditor

extension OMContext {
    public static let swiftGameEngineContext: OMContext = {
        let context = OMContext()
        do {
            try context.registerObjects([
                .make(name: "Node", { Node.init() }),
                .make(name: "Object3D", { Object3DNode.init() }),
                .make(name: "Light", { LightNode() }),
                .make(name: "Plane", { Plane() }),
                .make(name: "WADNode", { WADNode() }),
                .make(name: "GrassNode", { GrassNode() })
            ])
            try context.registerModifications([
                .make(name: "Base", { NodeBaseModification.init() }),
                .make(name: "Object3D", { Object3DNodeModification.init() }),
                .make(name: "Light", { NodeLightModification.init() }),
                .make(name: "Texture", { TextureModification.init() }),
                .make(name: "WAD", { WADNodeModification.init() }),
                .make(name: "Grass", { GrassNodeModification.init() })
            ])
        }
        catch {
            print(error)
        }
        return context
    }()
}
