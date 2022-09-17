import Foundation
import MetalKit

public final class Sprite2DInput: ScreenSizeChangable {
    public struct Point {
        let position: vector_float2
        let uv: vector_float2
    }

    var renderSize: vector_uint2

    public var points: [Point]
    public var texture: ITexture

    private let uvMetalBufferCache = MetalBufferCache()
    private let positionCache = MetalBufferCache()

    public init(renderSize: vector_uint2 = .zero, texture: ITexture, points: [Point]) {
        self.renderSize = renderSize
        self.texture = texture
        self.points = points
    }
}

extension Sprite2DInput: MetalInputRenderEncodable {
    static var render: MetalMetalRenderFunctionName? {
        return .init(vertexFunction: "sprite2DVertexShader", fragmentFunction: "sprite2DFragmentShader")
    }

    func renderEncode(_ encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
        guard let texture = self.texture.getMLTexture(device: device) else {
            return
        }
        let position = points.map { $0.position }
        let uv = points.map { $0.uv }
        let uvBuffer = try uvMetalBufferCache.getBuffer(uv, device: device)
        let positionBuffer = try positionCache.getBuffer(position, device: device)

        encoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uvBuffer, offset: 0, index: 1)
        var renderSize = self.renderSize
        encoder.setVertexBytes(&renderSize, length: MemoryLayout<vector_uint2>.size, index: 2)
        encoder.setFragmentTexture(texture, index: 0)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: points.count)
    }
}
