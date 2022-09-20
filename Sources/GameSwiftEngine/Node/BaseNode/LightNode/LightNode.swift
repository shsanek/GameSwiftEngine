import simd

/// Node light source
public final class LightNode: Node, CameraNodeDelegate {
    let provider = LightProvider()

    private let camera: CameraNode = CameraNode()

    /// Active dynamic shadow, Only 5 dynamic shadows can be active at the same time
    ///  work with angle < .pi
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

    /// Color of light
    public var color: vector_float3 {
        set {
            provider.light.color = newValue
        }
        get {
            provider.light.color
        }
    }

    /// Power light
    /// `power = power / (length ^ 2)` -  excluding direction
    public var power: GEFloat {
        set {
            provider.light.power = newValue
        }
        get {
            provider.light.power
        }
    }

    /// step rounding for power ,to create non-smooth gradients
    public var step: GEFloat? {
        set {
            provider.light.ceilStep = newValue ?? -1
        }
        get {
            provider.light.ceilStep
        }
    }

    /// Angle for light direction
    /// `direction = (0, 0, 1)` - rotate the node to change
    /// Power does not change at all values inside the angle
    /// To make the fade use `attenuationAngle`
    public var angle: GEFloat? {
        set {
            provider.light.angle = newValue ?? -1
        }
        get {
            provider.light.angle
        }
    }

    // Liner fade angle
    // power = 1 - (currentAngle - angle) / attenuationAngle
    public var attenuationAngle: GEFloat? {
        set {
            provider.light.attenuationAngle = newValue ?? -1
        }
        get {
            provider.light.attenuationAngle
        }
    }


    /// The number of frames to skip when drawing a dynamic shadow
    public var shadowSkipFrame: Int = 2 {
        didSet {
            if shadowSkipFrame < 0 {
                shadowSkipFrame = 0
            }
        }
    }

    public override var isHidden: Bool {
        didSet {
            provider.isHidden = isHidden
        }
    }

    public override func didMoveSceene(oldSceene: SceneNode?, scene: SceneNode?) {
        super.didMoveSceene(oldSceene: oldSceene, scene: scene)
        oldSceene?.lightController.removeLight(self)
        scene?.lightController.addLight(self)
    }

    private var shadowMapInfo: ShadowMapInfo?

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        guard isShadow, let mapInfo = getActualShadowMapInfo() else {
            provider.light.shadowMap = -1
            camera.isActive = false
            return
        }
        camera.renderInfo.renderAttributes.set(.ignoreColorBuffer, value: true)
        camera.projectionMatrix = perspectiveMatrix(
            fovyRadians: (angle ?? 0) + (attenuationAngle ?? 0),
            aspectRatio: 1
        )
        camera.renderInfo.size = .init(
            width: GEFloat(mapInfo.texture.width),
            height: GEFloat(mapInfo.texture.height)
        )
        camera.renderInfo.depthInfo.depth = mapInfo.texture
        camera.renderInfo.depthInfo.arrayIndex = mapInfo.index
        camera.renderInfo.colorInfo.color = TextureFactory.makeColorTexture(size: .init(width: 512, height: 512))

        provider.light.shadowShiftZ = camera.projectionMatrix[3][2]
        provider.light.shadowMap = Int32(mapInfo.index)
    }

    private func getActualShadowMapInfo() -> ShadowMapInfo? {
        let shadowMapInfo: ShadowMapInfo?
        if let current = self.shadowMapInfo, current.isActual {
            shadowMapInfo = current
            camera.isActive = false
        } else {
            shadowMapInfo = scene?.lightController.getTextureForShadow(lock: shadowSkipFrame + 1)
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
