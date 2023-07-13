import simd

extension matrix_float4x4: Codable {
    struct Model: Codable {
        let a: vector_float4
        let b: vector_float4
        let c: vector_float4
        let d: vector_float4
    }

    public init(from decoder: Decoder) throws {
        let model = try decoder.decode(Model.self)
        self.init(columns: (model.a, model.b, model.c, model.d))
    }

    public func encode(to encoder: Encoder) throws {
        let model = Model(a: columns.0, b: columns.1, c: columns.2, d: columns.3)
        try encoder.encode(model)
    }
}

extension vector_float4 {
    public var xyz: vector_float3 {
        return .init(x, y, z)
    }
}

extension vector_float3 {
    var to4: vector_float4 {
        return .init(x, y, z, 1)
    }
}
