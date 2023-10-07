import simd

extension ObjImporter.Object {
    public func geometryForInput(with transform: matrix_float4x4 = .init(1)) -> [VertexInput] {
        items.map {
            let position: vector_float4 = matrix_multiply(transform, vector_float4($0.position, 1))
            return .init(
                position: .init(x: position.x, y: position.y, z: position.z),
                uv: $0.uv
            )
        }
    }
}
