import simd

public final class GravitationController {
    private var lastPosition: vector_float3?
    private var gAcseleration: Float = 3
    private var gSpeed: Float = 0
    private var speed: vector_float3 = .zero
    private weak var node: Node?

    public init(node: Node) {
        self.node = node
    }

    public func update(with time: Float) {
        guard
            let lastPosition = lastPosition,
            let node = node,
            let dynamicCollisionRadius = node.dynamicCollisionRadius
        else {
            lastPosition = node?.position
            return
        }
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
