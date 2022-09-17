import simd

struct Rect3D {
    var a: vector_float3
    var b: vector_float3
    var c: vector_float3
    var d: vector_float3
}

struct Rect2D {
    var a: vector_float2 = .init(x: 0, y: 1)
    var b: vector_float2 = .init(x: 0, y: 0)
    var c: vector_float2 = .init(x: 1, y: 0)
    var d: vector_float2 = .init(x: 1, y: 1)
}
