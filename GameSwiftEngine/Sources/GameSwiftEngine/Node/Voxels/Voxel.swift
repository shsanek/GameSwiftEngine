public final class Voxel {
    public private(set) var containers: [ObjectIdentifier: Node] = [:]

    func addNode(_ node: Node) {
        containers[ObjectIdentifier(node)] = node
    }

    func removeNode(_ node: Node) {
        containers[ObjectIdentifier(node)] = nil
    }
}

public final class UnvoxelGroup {
    public private(set) var containers: [ObjectIdentifier: Node] = [:]

    func addNode(_ node: Node) {
        containers[ObjectIdentifier(node)] = node
    }

    func removeNode(_ node: Node) {
        containers[ObjectIdentifier(node)] = nil
    }
}
