import simd

public final class LightNode: Node, CameraNodeDelegate {
    let provider = LightProvider()

    private let camera: CameraNode = CameraNode()

    public var isShadow: Bool = false {
        didSet {
            if isShadow == oldValue {
                return
            }
            if isShadow {
                addSubnode(camera)
                camera.delegate = self
            } else {
                camera.removeFromParent()
                camera.delegate = nil
            }
        }
    }

    public var color: vector_float3 {
        set {
            provider.light.color = newValue
        }
        get {
            provider.light.color
        }
    }
    public var power: Float {
        set {
            provider.light.power = newValue
        }
        get {
            provider.light.power
        }
    }
    public var step: Float? {
        set {
            provider.light.ceilStep = newValue ?? -1
        }
        get {
            provider.light.ceilStep
        }
    }
    public var angle: Float? {
        set {
            provider.light.angle = newValue ?? -1
        }
        get {
            provider.light.angle
        }
    }
    public var attenuationAngle: Float? {
        set {
            provider.light.attenuationAngle = newValue ?? -1
        }
        get {
            provider.light.attenuationAngle
        }
    }

    public override var isHidden: Bool {
        didSet {
            provider.isHidden = isHidden
        }
    }

    public override func didMoveSceene(oldSceene: SceeneNode?, sceene: SceeneNode?) {
        super.didMoveSceene(oldSceene: oldSceene, sceene: sceene)
        oldSceene?.lightController.removeLight(self)
        sceene?.lightController.addLight(self)
    }

    public var shadowSkipFrame: Int = 2 {
        didSet {
            if shadowSkipFrame < 0 {
                shadowSkipFrame = 0
            }
        }
    }

    private var shadowMapInfo: ShadowMapInfo?

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        guard isShadow, let mapInfo = getActualShadowMapInfo() else {
            provider.light.shadowMap = -1
            camera.isActive = false
            return
        }
        camera.projectionMatrix = perspectiveMatrix(
            fovyRadians: (angle ?? 0) + (attenuationAngle ?? 0),
            aspectRatio: 1
        )
        camera.renderInfo.depthInfo.depth = mapInfo.texture
        camera.renderInfo.depthInfo.arrayIndex = mapInfo.index

        provider.light.shadowShiftZ = camera.projectionMatrix[3][2]
        provider.light.shadowMap = Int32(mapInfo.index)
    }

    private func getActualShadowMapInfo() -> ShadowMapInfo? {
        let shadowMapInfo: ShadowMapInfo?
        if let current = self.shadowMapInfo, current.isActual {
            shadowMapInfo = current
            camera.isActive = false
        } else {
            shadowMapInfo = sceene?.lightController.getTextureForShadow(lock: shadowSkipFrame + 1)
            camera.isActive = true
            self.shadowMapInfo = shadowMapInfo
        }
        return shadowMapInfo
    }

    public func didUpdateRenderResault(_ camera: CameraNode) {
        let cameraMatrix = matrix_multiply(
            camera.projectionMatrix,
            camera.absoluteTransform.inverse
        )
        provider.light.shadowProjection = cameraMatrix
    }

    func calculate() {
        let vector = vector_float4(0, 0, 0, 1)
        let transform = absoluteTransform
        let dVectore = matrix_multiply(transform, vector)
        provider.light.position = .init(x: dVectore.x, y: dVectore.y, z: dVectore.z)
        let direction = matrix_multiply(transform, vector_float4(0, 0, -1, 1)) - dVectore
        provider.light.direction = .init(x: direction.x, y: direction.y, z: direction.z)
    }
}
