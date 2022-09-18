import GameSwiftEngine

protocol INodeActive: Node {
    func action()
}

class ActiveContainer: Node, IPlayerActiveble {
    let node: INodeActive

    init(node: INodeActive) {
        self.node = node
        super.init()
        addSubnode(node)
    }

    func action(_ player: PlayerNode) {
        node.action()
    }
}
