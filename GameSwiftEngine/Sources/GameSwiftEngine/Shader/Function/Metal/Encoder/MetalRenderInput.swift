import MetalKit

struct MetalRenderInput {
    let time: Double
    let device: MTLDevice
    let descriptor: MTLRenderPassDescriptor
    let buffer: MTLCommandBuffer
    let encoder: MTLRenderCommandEncoder
    let size: vector_float2
    var projectionMatrix: matrix_float4x4
    var currentPosition: matrix_float4x4 = .init(1)
    var lightInfo: LightInfo?

    var renderType: RenderType

    enum RenderType {
        case mainRender
        case shadowRender
        case customRender
    }
}
