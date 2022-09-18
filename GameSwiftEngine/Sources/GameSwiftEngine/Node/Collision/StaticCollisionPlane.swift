import simd

public struct StaticCollisionPlane {
    public let transform: matrix_float4x4
    public let size: vector_float2

    public init(transform: matrix_float4x4, size: vector_float2) {
        self.transform = transform
        self.size = size
    }
}
