import GameSwiftEngine

final class ZombeeNode: Node {
    override init() {
        super.init()
        loadModel()
    }

    private func loadModel() {
        guard let object = InterQuakeImporter.loadFile("zombee") else {
            return
        }
        let node = Object3DNode(object: object, texture: Texture.load(in: "TECH_0F"))
        var animation = NodeAnimation.updateFrames((0..<node.frameCount).map { $0 })
        animation.duration = 3
        animation.animationFunction = .default
        animation.repeatCount = 0
        addSubnode(node)
        node.addAnimation(animation)
        node.scale(to: .init(0.1, 0.1, 0.1))
        node.move(to: .init(7, -0.5, 2))
        node.rotate(on: -.pi/2, axis: .init(1, 0, 0))
    }
}
