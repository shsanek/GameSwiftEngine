import GameSwiftEngine

protocol INodeActive: Node {
    func action()
}

class ActiveContainer: Node, INodeActivable {
    let node: INodeActive

    init(node: INodeActive) {
        self.node = node
        super.init()
        addSubnode(node)
    }

    func active() {
        node.action()
    }
}
