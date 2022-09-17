import MetalKit

struct MetalRenderInput {
    let time: Double
    let device: MTLDevice
    let descriptor: MTLRenderPassDescriptor
    let encoder: MTLRenderCommandEncoder
    let size: vector_float2
    let attributes: RenderAttributes
    let functionCache: RenderFunctionsCache
    var projectionMatrix: matrix_float4x4
    var currentPosition: matrix_float4x4 = .init(1)
    var lightInfo: LightInfo?
}
