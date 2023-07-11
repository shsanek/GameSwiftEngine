import GameSwiftEngine
import Foundation

final class ZombeeNode: Node {
    static let object = InterQuakeImporter.loadFile("Resources/Objects/zombee", bundle: Bundle.module)
    override init() {
        super.init()
        loadModel()
    }

    private func loadModel() {
        guard let object = ZombeeNode.object else {
            return
        }
        let node = Object3DNode(
            object: object,
            texture: Texture.load(in: "Resources/Textures/SUPPORT_7C.png", bundle: Bundle.module)
        )
        var animation = NodeAnimation.updateFrames((0..<node.frameCount).map { $0 })
        animation.duration = 3
        animation.animationFunction = .default
        animation.repeatCount = 0
        addSubnode(node)
        node.addAnimation(animation)
        node.scale(to: .init(0.1, 0.1, 0.1))
        node.move(to: .init(0, -0.5, 0))
        node.rotate(on: -.pi/2, axis: .init(1, 0, 0))

        let light = LightNode()
        light.color = .init(0, 1, 0)
        light.power = 0.005
        addSubnode(light)

        rotate(on: .pi, axis: .init(0, 1, 0))

        var animation2 = NodeAnimation.move(to: .init(x: 7, y: 0, z: 1))
        animation2.duration = 30
        //addAnimation(animation2)

    }
}
