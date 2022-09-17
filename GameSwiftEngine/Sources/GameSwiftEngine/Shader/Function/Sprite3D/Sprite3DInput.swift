import Foundation
import MetalKit
import simd

public final class Sprite3DInput: ProjectionChangable, PositionChangable, LightInfoChangable {
    public struct InputBoneBind {
        public var index: Int32
        public var width: Float32

        public static var empty: Self {
            .init(index: -1, width: 0)
        }

        public init(index: Int32, width: Float32) {
            self.index = index
            self.width = width
        }
    }

    public struct VertexInput: RawEncodable {
        public var position: vector_float3
        public var uv: vector_float2

        public var boneA: InputBoneBind = .empty
        public var boneB: InputBoneBind = .empty
        public var boneC: InputBoneBind = .empty
        public var boneD: InputBoneBind = .empty

        public init(position: vector_float3, uv: vector_float2) {
            self.position = position
            self.uv = uv
        }
    }

    public struct BoneTransform {
        public let transform: matrix_float4x4
    }

    var projectionMatrix: matrix_float4x4
    var positionMatrix: matrix_float4x4 = .init(1)
    var lightInfo: LightInfo?

    public var texture: Texture?
    public let bones = OptionalBufferContainer<matrix_float4x4>(.init(1))

    public let vertexIndexs = OptionalBufferContainer<UInt32>(0)
    public let vertexs = BufferContainer<VertexInput>()

    public init(
        texture: Texture?,
        projectionMatrix: matrix_float4x4 = .init(1),
        vertexs: [VertexInput]
    ) {
        self.projectionMatrix = projectionMatrix
        self.vertexs.values = vertexs
        self.texture = texture
    }

    public init(
        texture: Texture?,
        geometry: ObjImporter.Object,
        transform: matrix_float4x4 = .init(1)
    ) {
        self.texture = texture
        self.vertexs.values = geometry.geometryForInput(with: transform)
        self.projectionMatrix = .init(1)
    }
}

extension Sprite3DInput: MetalInputRenderEncodable {
    static var render: MetalMetalRenderFunctionName? {
        return .init(vertexFunction: "sprite3DVertexShader", fragmentFunction: "sprite3DFragmentShader")
    }

    func renderEncode(_ encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
        guard let texture = self.texture?.getMLTexture(device: device) else {
            return
        }
        let light = try? lightInfo.getBuffer(for: device)
        let input = try vertexs.getBuffer(with: device)

        encoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 0)
        encoder.setVertexBytes(&positionMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 1)

        encoder.setVertexBuffer(input, offset: 0, index: 2)
        encoder.setVertexBuffer(try bones.getBuffer(with: device), offset: 0, index: 3)

        var bounesCount: Int32 = Int32(bones.count)
        encoder.setVertexBytes(&bounesCount, length: MemoryLayout<Int32>.stride, index: 4)

        // Fragment
        var count: Int32 = Int32(light?.1 ?? 0)
        if let light = light?.0 {
            encoder.setFragmentBuffer(light, offset: 0, index: 0)
        } else {
            var light = LightInfo.Light(position: .zero, color: .zero, power: 0)
            encoder.setFragmentBytes(&light, length: MemoryLayout<LightInfo.Light>.stride, index: 0)
        }
        encoder.setFragmentBytes(&count, length: MemoryLayout<Int32>.stride, index: 1)
        encoder.setFragmentTexture(texture, index: 0)

        if let indexsBuffer = try vertexIndexs.getOptionalBuffer(with: device) {
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: vertexIndexs.count,
                indexType: .uint32,
                indexBuffer: indexsBuffer,
                indexBufferOffset: 0
            )
        } else {
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexs.count)
        }

    }
}
