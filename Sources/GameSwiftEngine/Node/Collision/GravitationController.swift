import simd

public final class GravitationController {
    private var lastPosition: vector_float3?
    private var gAcseleration: GEFloat = 3
    private var gSpeed: GEFloat = 0
    private var speed: vector_float3 = .zero
    private weak var node: Node?

    public init(node: Node) {
        self.node = node
    }

    public func update(with time: GEFloat) {
        guard
            let lastPosition = lastPosition,
            let node = node,
            node.dynamicCollisionElement.isActive
        else {
            lastPosition = node?.position
            return
        }
        let dynamicCollisionRadius = node.dynamicCollisionElement.radius
        let v = (node.position - lastPosition) / time
        if v.y < -gSpeed {
            gSpeed = 0
        }
        gSpeed += gAcseleration * time
        let result = min(gSpeed * time, dynamicCollisionRadius / 3 * 2)
        node.move(on: .init(x: 0, y: -result, z: 0))
        self.lastPosition = node.position
    }
}
