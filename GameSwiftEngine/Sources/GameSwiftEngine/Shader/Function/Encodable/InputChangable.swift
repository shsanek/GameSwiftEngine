import simd

protocol ScreenSizeChangable {
    var renderSize: vector_uint2 { get set }
}

protocol ProjectionChangable {
    var projectionMatrix: matrix_float4x4 { get set }
}

protocol PositionChangable {
    var positionMatrix: matrix_float4x4 { get set }
}

protocol LightInfoChangable {
    var lightInfo: LightInfo? { get set }
}
