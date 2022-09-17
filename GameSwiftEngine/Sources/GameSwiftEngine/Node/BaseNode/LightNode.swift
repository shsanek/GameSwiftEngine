import simd

public final class LightNode: Node {
    let provider = LightProvider()

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

    func calculate() {
        let vector = vector_float4(0, 0, 0, 1)
        let transform = absoluteTransform
        let dVectore = matrix_multiply(transform, vector)
        provider.light.position = .init(x: dVectore.x, y: dVectore.y, z: dVectore.z)
        let direction = matrix_multiply(transform, vector_float4(0, 0, -1, 1)) - dVectore
        provider.light.direction = .init(x: direction.x, y: direction.y, z: direction.z)
    }
}

