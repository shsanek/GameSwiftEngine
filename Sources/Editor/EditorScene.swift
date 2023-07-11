import Foundation
import ObjectEditor
import GameSwiftEngine

public final class GameScene: SceneNode {
    public init(rootNode: Node) {
        super.init()
        addSubnode(rootNode)
        mainCamera = camers.first(where: { $0.omIdentifier == "mainCamera" }) ?? mainCamera
    }
}

public final class EditorScene: SceneNode {
    public let rootNode = Node()
    public let editNode = Node()

    public override init() {
        super.init()
        addSubnode(rootNode)
        addSubnode(editNode)
    }
}
