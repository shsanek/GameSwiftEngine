import Foundation
import MetalKit
import simd

extension RenderAttributesKey {
    static var ignoreColorBuffer: RenderAttributesKey<Bool> {
        .init(key: "ignoreColorBuffer", type: Bool.self)
    }
}

public enum Material: UInt32 {
    case `default` = 0
    case mirror = 1
}

public struct InputBoneBind: Hashable, Codable {
    public var index: Int32
    public var width: GEFloat

    public static var empty: Self {
        .init(index: -1, width: 0)
    }

    public init(index: Int32, width: GEFloat) {
        self.index = index
        self.width = width
    }
}

public struct VertexInput: RawEncodable, Hashable, Codable {
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

public final class Sprite3DInput: ProjectionChangable, PositionChangable, LightInfoChangable {
    var projectionMatrix: matrix_float4x4
    var positionMatrix: matrix_float4x4 = .init(1)
    var lightInfo: LightInfo?
    var material: Material = .default

    public var texture: ITexture?
    public let bones = OptionalBufferContainer<matrix_float4x4>(.init(1))

    public let vertexIndexs = OptionalBufferContainer<UInt32>(0)
    public let vertexs = BufferContainer<VertexInput>()

    public init(
        texture: ITexture?,
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

extension Sprite3DInput: MetalRenderHandler {
    private static let mainFuntion = MetalRenderFunctionName(
        vertexFunction: "sprite3DVertexShader",
        fragmentFunction: "sprite3DFragmentShader"
    )

    private static let emptyFuntion = MetalRenderFunctionName(
        vertexFunction: "sprite3DVertexShader",
        fragmentFunction: "sprite3DEmptyFragmentShader"
    )

    private static let mirrorFuntion = MetalRenderFunctionName(
        vertexFunction: "sprite3DVertexShader",
        fragmentFunction: "sprite3DMirrorFragmentShader"
    )


    static var dependencyFunctions: [MetalRenderFunctionName] {
        [mainFuntion, emptyFuntion, mirrorFuntion]
    }

    func renderEncode(
        _ encoder: MTLRenderCommandEncoder,
        device: MTLDevice,
        attributes: RenderAttributes,
        functionsСache: RenderFunctionsCache
    ) throws {
        if attributes.getValue(.ignoreColorBuffer) {
            try functionsСache
                .get(with: Self.emptyFuntion, device: device)
                .start(encoder: encoder)
        } else {
            switch material {
            case .default:
                try functionsСache
                    .get(with: Self.mainFuntion, device: device)
                    .start(encoder: encoder)
            case .mirror:
                try functionsСache
                    .get(with: Self.mirrorFuntion, device: device)
                    .start(encoder: encoder)
            }

            try prepareFragment(encoder: encoder, device: device)
        }
        try prepareVertex(encoder: encoder, device: device)
        try render(encoder: encoder, device: device)
    }

    private func render(encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
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

    private func prepareFragment(encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
        let texture = self.texture?.metal?.getMLTexture(device: device)
        let light = try? lightInfo.getBuffer(for: device)

        encoder.setFragmentTexture(texture, index: 0)

        guard material != .mirror else {
            return
        }
        var count: Int32 = Int32(light?.1 ?? 0)
        if let light = light?.0 {
            encoder.setFragmentBuffer(light, offset: 0, index: 0)
        } else {
            var light = LightInfo.Light(position: .zero, color: .zero, power: 0)
            encoder.setFragmentBytes(&light, length: MemoryLayout<LightInfo.Light>.stride, index: 0)
        }
        if let lightInfo = lightInfo {
            encoder.setFragmentTexture(lightInfo.shadowMapTexture?.metal?.getMLTexture(device: device), index: 1)
        }
        encoder.setFragmentBytes(&count, length: MemoryLayout<Int32>.stride, index: 1)

        var softShadowInfo = lightInfo?.softShadowsSetting ?? .init()
        encoder.setFragmentBytes(&softShadowInfo, length: MemoryLayout<LightInfo.SoftShadowsSetting>.stride, index: 2)
    }

    private func prepareVertex(encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
        let input = try vertexs.getBuffer(with: device)

        encoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 0)
        encoder.setVertexBytes(&positionMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 1)

        encoder.setVertexBuffer(input, offset: 0, index: 2)
        encoder.setVertexBuffer(try bones.getBuffer(with: device), offset: 0, index: 3)

        var bounesCount: Int32 = Int32(bones.count)
        encoder.setVertexBytes(&bounesCount, length: MemoryLayout<Int32>.stride, index: 4)
    }
}

public final class GeometryContainer {
    public let vertexes: [VertexInput]
    public let indexes: [UInt32]
    public let bonesCount: Int

    public init(
        vertexes: [VertexInput],
        indexes: [UInt32],
        bonesCount: Int
    ) {
        self.vertexes = vertexes
        self.indexes = indexes
        self.bonesCount = bonesCount
    }
}

enum Object3DControllerEvent {
    case updateIdentifier(_ old: ArrayIdentifier)

    case updateHidden
    case updateInfo
    case updateBones
}

public final class Object3DController {
    var updateHandler: ((Object3DControllerEvent) -> Void)?

    var arrayIdentifier: ArrayIdentifier {
        let result = identifierStorage ?? .init(
            textureIdentifier: texture?.identifier,
            materialIdentifier: material.rawValue,
            vertexesIdentifier: ObjectIdentifier(geometry)
        )
        identifierStorage = result
        return result
    }

    private var identifierStorage: ArrayIdentifier?

    public var geometry: GeometryContainer {
        didSet {
            guard geometry !== oldValue else { return }
            let identifier = arrayIdentifier
            identifierStorage = nil
            updateHandler?(.updateIdentifier(identifier))
        }
    }
    public var texture: ITexture? {
        didSet {
            guard texture?.identifier != oldValue?.identifier else { return }
            let identifier = arrayIdentifier
            identifierStorage = nil
            updateHandler?(.updateIdentifier(identifier))
        }
    }
    public var textureIndex: UInt32 = 0 {
        didSet {
            guard oldValue != textureIndex else { return }
            updateHandler?(.updateInfo)
        }
    }

    public var isHidden: Bool = false {
        didSet {
            guard oldValue != isHidden else { return }
            updateHandler?(.updateHidden)
        }
    }

    public var modelMatrix: matrix_float4x4 = .init() {
        didSet {
            guard oldValue != modelMatrix else { return }
            updateHandler?(.updateInfo)
        }
    }

    public var material: Material = .default {
        didSet {
            guard oldValue != material else { return }
            let identifier = arrayIdentifier
            identifierStorage = nil
            updateHandler?(.updateIdentifier(identifier))
        }
    }

    public var bones: [matrix_float4x4] = [.init()] {
        didSet {
            guard oldValue != bones else { return }
            updateHandler?(.updateBones)
        }
    }


    public init(
        geometry: GeometryContainer,
        texture: ITexture?
    ) {
        self.geometry = geometry
        self.texture = texture
    }
}

struct ArrayIdentifier: Hashable {
    let textureIdentifier: ObjectIdentifier?
    let materialIdentifier: UInt32
    let vertexesIdentifier: ObjectIdentifier

    init(
        textureIdentifier: ObjectIdentifier?,
        materialIdentifier: UInt32,
        vertexesIdentifier: ObjectIdentifier
    ) {
        self.textureIdentifier = textureIdentifier
        self.materialIdentifier = materialIdentifier
        self.vertexesIdentifier = vertexesIdentifier
    }
}

struct ModelInfo: RawEncodable {
    let modelMatrix: matrix_float4x4
    let textureIndex: UInt32
}

final class Objects3DArray: ProjectionChangable, LightInfoChangable {
    var projectionMatrix: matrix_float4x4 = .init(1) {
        didSet {
            guard oldValue != projectionMatrix else { return }
            projectionMatrixBuffer.values = [projectionMatrix]
        }
    }

    var lightInfo: LightInfo?

    private var projectionMatrixBuffer = BufferContainer<matrix_float4x4>()
    private var vertexes = BufferContainer<VertexInput>()
    private var vertexInfos = BufferContainer<UInt32>()

    private var modelInfo = BufferContainer<ModelInfo>()
    private var bones = BufferContainer<matrix_float4x4>()

    private let geometry: GeometryContainer
    private let material: Material
    private let texture: ITexture?

    final class PositionInfo {
        var position: Int
        let controller: Object3DController

        init(position: Int, controller: Object3DController) {
            self.position = position
            self.controller = controller
        }
    }

    private var positionInfos: [ObjectIdentifier: PositionInfo] = [:]

    init(geometry: GeometryContainer, material: Material, texture: ITexture) {
        self.geometry = geometry
        self.material = material
        self.texture = texture
        self.vertexInfos.values = geometry.indexes
        self.vertexes.values = geometry.vertexes
    }

    init(controller: Object3DController) {
        self.geometry = controller.geometry
        self.texture = controller.texture
        self.material = controller.material
        self.vertexInfos.values = controller.geometry.indexes
        self.vertexes.values = controller.geometry.vertexes
    }

    func getPosInfo(_ controller: Object3DController) throws -> PositionInfo {
        let identifier = ObjectIdentifier(controller)
        guard let posInfo = positionInfos[identifier] else {
            throw RenderError.message("controller not found")
        }
        return posInfo
    }

    func addController(_ controller: Object3DController) throws {
        let identifier = ObjectIdentifier(controller)
        positionInfos[identifier] = .init(position: positionInfos.count, controller: controller)
        modelInfo.values.append(.init(modelMatrix: controller.modelMatrix, textureIndex: controller.textureIndex))
        controller.bones.forEach { self.bones.values.append($0) }
    }

    func removeController(_ controller: Object3DController) throws {
        let posInfo = try getPosInfo(controller)
        let lastIndex = positionInfos.count - 1
        let lastPosInfo = positionInfos.first(where: { $0.value.position == lastIndex })?.value ?? posInfo
        lastPosInfo.position = posInfo.position

        try updateBones(lastPosInfo.controller)
        try updateInfo(lastPosInfo.controller)

        bones.values.removeLast(geometry.bonesCount)
        modelInfo.values.removeLast()

        positionInfos.removeValue(forKey: ObjectIdentifier(controller))
    }

    func updateBones(_ controller: Object3DController) throws {
        let posInfo = try getPosInfo(controller)
        let bCount = geometry.bonesCount

        controller.bones.enumerated().forEach {
            bones.values[bCount * posInfo.position + $0.offset] = $0.element
        }
    }

    func updateInfo(_ controller: Object3DController) throws {
        let posInfo = try getPosInfo(controller)
        modelInfo.values[posInfo.position] = .init(
            modelMatrix: controller.modelMatrix,
            textureIndex: controller.textureIndex
        )
    }
}


public final class NodePool {
    private(set) var nodes: [ObjectIdentifier: Node] = [:]

    public func add(_ node: Node) {
        nodes[ObjectIdentifier(node)] = node
    }

    public func remove(_ node: Node) {
        nodes.removeValue(forKey: ObjectIdentifier(node))
    }

    public func clear() {
        nodes = [:]
    }
}

public final class Objects3DArraysManager {
    private(set) var arrays: [ArrayIdentifier: Objects3DArray] = [:]

    public func addController(_ controller: Object3DController) throws {
        controller.updateHandler = { [weak self, weak controller] in
            guard let controller = controller else { return }
            self?.update(with: $0, controller: controller)
        }
        try addControllerToArray(controller)
    }

    public func removeController(_ controller: Object3DController) throws {
        try arrays[controller.arrayIdentifier]?.removeController(controller)
        controller.updateHandler = nil
    }

    private func addControllerToArray(_ controller: Object3DController) throws {
        let array = arrays[controller.arrayIdentifier] ?? .init(controller: controller)
        arrays[controller.arrayIdentifier] = array
        try array.addController(controller)
    }

    private func update(with event: Object3DControllerEvent, controller: Object3DController) {
        switch event {
        case .updateIdentifier(let identifier):
            try? arrays[identifier]?.removeController(controller)
            try? addControllerToArray(controller)
        case .updateHidden:
            if controller.isHidden {
                try? arrays[controller.arrayIdentifier]?.removeController(controller)
            } else {
                try? addControllerToArray(controller)
            }
        case .updateInfo:
            try? arrays[controller.arrayIdentifier]?.updateInfo(controller)
        case .updateBones:
            try? arrays[controller.arrayIdentifier]?.updateBones(controller)
        }
    }
}

extension Objects3DArray: MetalRenderHandler {
    private static let mainFuntion = MetalRenderFunctionName(
        vertexFunction: "sprite3DVertexShader",
        fragmentFunction: "sprite3DFragmentShader"
    )

    private static let emptyFuntion = MetalRenderFunctionName(
        vertexFunction: "sprite3DVertexShader",
        fragmentFunction: "sprite3DEmptyFragmentShader"
    )

    private static let mirrorFuntion = MetalRenderFunctionName(
        vertexFunction: "sprite3DVertexShader",
        fragmentFunction: "sprite3DMirrorFragmentShader"
    )


    static var dependencyFunctions: [MetalRenderFunctionName] {
        [mainFuntion, emptyFuntion, mirrorFuntion]
    }

    func renderEncode(
        _ encoder: MTLRenderCommandEncoder,
        device: MTLDevice,
        attributes: RenderAttributes,
        functionsСache: RenderFunctionsCache
    ) throws {
        if attributes.getValue(.ignoreColorBuffer) {
            try functionsСache
                .get(with: Self.emptyFuntion, device: device)
                .start(encoder: encoder)
        } else {
            switch material {
            case .default:
                try functionsСache
                    .get(with: Self.mainFuntion, device: device)
                    .start(encoder: encoder)
            case .mirror:
                try functionsСache
                    .get(with: Self.mirrorFuntion, device: device)
                    .start(encoder: encoder)
            }

            try prepareFragment(encoder: encoder, device: device)
        }
        try prepareVertex(encoder: encoder, device: device)
        try render(encoder: encoder, device: device)
    }

    private func render(encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
        encoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: geometry.vertexes.count * positionInfos.count
        )
    }

    private func prepareFragment(encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
        let texture = self.texture?.metal?.getMLTexture(device: device)
        let light = try? lightInfo.getBuffer(for: device)

        encoder.setFragmentTexture(texture, index: 0)

        guard material != .mirror else {
            return
        }
        var count: Int32 = Int32(light?.1 ?? 0)
        if let light = light?.0 {
            encoder.setFragmentBuffer(light, offset: 0, index: 0)
        } else {
            var light = LightInfo.Light(position: .zero, color: .zero, power: 0)
            encoder.setFragmentBytes(&light, length: MemoryLayout<LightInfo.Light>.stride, index: 0)
        }
        if let lightInfo = lightInfo {
            encoder.setFragmentTexture(lightInfo.shadowMapTexture?.metal?.getMLTexture(device: device), index: 1)
        }
        encoder.setFragmentBytes(&count, length: MemoryLayout<Int32>.stride, index: 1)

        var softShadowInfo = lightInfo?.softShadowsSetting ?? .init()
        encoder.setFragmentBytes(&softShadowInfo, length: MemoryLayout<LightInfo.SoftShadowsSetting>.stride, index: 2)
    }

    private func prepareVertex(encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
        encoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 0)
        encoder.setVertexBuffer(try modelInfo.getBuffer(with: device), offset: 0, index: 1)
        encoder.setVertexBuffer(try vertexes.getBuffer(with: device), offset: 0, index: 2)
        encoder.setVertexBuffer(try bones.getBuffer(with: device), offset: 0, index: 3)

        var bounesCount: Int32 = Int32(geometry.bonesCount)
        encoder.setVertexBytes(&bounesCount, length: MemoryLayout<Int32>.stride, index: 4)

        encoder.setVertexBuffer(try vertexInfos.getBuffer(with: device), offset: 0, index: 5)

        var vertexCount: Int32 = Int32(geometry.indexes.count)
        encoder.setVertexBytes(&vertexCount, length: MemoryLayout<Int32>.stride, index: 6)
    }
}
