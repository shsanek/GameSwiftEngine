import Foundation
import MetalKit


public final class Grid3DInput: ScreenSizeChangable, PositionChangable, ProjectionChangable {
    var renderSize: vector_uint2 = .zero
    var positionMatrix: matrix_float4x4 = .init(1)
    var projectionMatrix: matrix_float4x4 = .init(1)
    var scale: Float = 1

    private let points: [vector_float2] = [
        .init(x: -1, y: -1),
        .init(x: -1, y: 1),
        .init(x: 1, y: 1),

        .init(x: -1, y: -1),
        .init(x: 1, y: 1),
        .init(x: 1, y: -1)
    ]

    private let uvMetalBufferCache = MetalBufferCache()
    private let positionCache = MetalBufferCache()

    public init() {
    }
}

extension Grid3DInput: MetalRenderHandler {
    static let spriteFuntion = MetalRenderFunctionName(
        vertexFunction: "gridFullScreenVertexShader",
        fragmentFunction: "gridFullScreenFragmentShader"
    )

    static var dependencyFunctions: [MetalRenderFunctionName] {
        [spriteFuntion]
    }

    func renderEncode(
        _ encoder: MTLRenderCommandEncoder,
        device: MTLDevice,
        attributes: RenderAttributes,
        functionsСache: RenderFunctionsCache
    ) throws {
        try functionsСache
            .get(with: Self.spriteFuntion, device: device)
            .start(encoder: encoder)

        let positionBuffer = try positionCache.getBuffer(points, device: device)
        encoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)

        var projection = projectionMatrix * positionMatrix
        var inverse = projection.inverse
        encoder.setFragmentBytes(&projection, length: MemoryLayout<matrix_float4x4>.stride, index: 0)
        encoder.setFragmentBytes(&inverse, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
        var inverse2 = positionMatrix.inverse
        encoder.setFragmentBytes(&positionMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 2)
        encoder.setFragmentBytes(&inverse2, length: MemoryLayout<matrix_float4x4>.stride, index: 3)

        var renderSize = vector_float2(Float(renderSize.x), Float(renderSize.y));
        encoder.setFragmentBytes(&renderSize, length: MemoryLayout<vector_float2>.size, index: 4)

        encoder.setFragmentBytes(&scale, length: MemoryLayout<Float>.size, index: 5)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: points.count)
    }
}
