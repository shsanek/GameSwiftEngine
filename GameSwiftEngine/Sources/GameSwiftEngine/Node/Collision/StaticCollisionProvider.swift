import simd

public struct StaticCollisionPlane {
    public let transform: matrix_float4x4
    public let size: vector_float2

    public init(transform: matrix_float4x4, size: vector_float2) {
        self.transform = transform
        self.size = size
    }
}

final class DynamicCollisionProvider {
    var isActive: Bool = false

    weak var node: Node?

    init(
        node: Node?
    ) {
        self.node = node
    }
}

final class StaticCollisionProvider {
    var isActive: Bool = false

    weak var node: Node?

    var planes: [StaticCollisionPlane] = []

    init(
        node: Node?
    ) {
        self.node = node
        self.planes = []
    }
}
