import MetalKit
import simd

final class LightInfo {
    struct Light: RawEncodable {
        var position: vector_float3
        var color: vector_float3 = .one
        var power: GEFloat = 1
        var ceilStep: GEFloat = -1
        var direction: vector_float3 = .init(x: 0, y: 0, z: 1)
        var angle: GEFloat = .pi
        var attenuationAngle: GEFloat = -1
        var shadowProjection: matrix_float4x4 = .init(1)
        var shadowMap: Int32 = -1
        var shadowShiftZ: GEFloat = 0.1
    }

    struct LightInfoSetting: Hashable {
        var shadowMapSize: Size = .init(width: 512, height: 512)
        var maxShadow: Int = 5
        var shadowSoftWidth: Int = 3
    }

    struct SoftShadowsSetting: RawEncodable {
        var shadowMapSize: GEFloat = 512
        var shadowSoftWidth: Int32 = 2
        var shadowSoftSize: GEFloat = 3
    }

    let lightInputCache = MetalBufferCache()
    var lights: [LightProvider] = []
    var buffer: MTLBuffer? = nil
    weak var device: MTLDevice? = nil
    var count: Int = 0

    var settings = LightInfoSetting()

    private var shadowCount: Int {
        shadowMapInfos.filter { $0.isActual }.count
    }
    private(set) var softShadowsSetting: SoftShadowsSetting = SoftShadowsSetting()
    private(set) var shadowMapTexture: ITexture? = nil
    private var shadowMapInfos: [ShadowMapInfo] = []

    init() {
        updateSetting()
    }

    func loop() {
        shadowMapInfos.forEach { $0.loop() }
        shadowMapInfos = shadowMapInfos.map {
            $0.needRemaker ? .init(index: $0.index, texture: $0.texture) : $0
        }
    }

    func getTextureForShadow(lock: Int) -> ShadowMapInfo? {
        guard
            let freeInfo = shadowMapInfos.first(where: { !$0.isActual })
        else {
            return nil
        }
        freeInfo.retain(lock: lock)
        return freeInfo
    }

    private func updateSetting() {
        shadowMapInfos.forEach { $0.free() }
        let shadowMapTexture = TextureFactory.makeArrayDepthTexture(
            size: settings.shadowMapSize,
            count: settings.maxShadow
        )
        self.shadowMapTexture = shadowMapTexture
        shadowMapInfos = (0..<settings.maxShadow).map {
            ShadowMapInfo(index: $0, texture: shadowMapTexture)
        }

        softShadowsSetting.shadowMapSize = settings.shadowMapSize.width
        softShadowsSetting.shadowSoftWidth = Int32(settings.shadowSoftWidth)
        var total: Float = 0
        for x in -settings.shadowSoftWidth...settings.shadowSoftWidth {
            for y in -settings.shadowSoftWidth...settings.shadowSoftWidth {
                let fx = Float(x) / Float(settings.shadowSoftWidth)
                let fy = Float(y) / Float(settings.shadowSoftWidth)
                total += Float(2) - (fx * fx + fy * fy)
            }
        }
        softShadowsSetting.shadowSoftSize = total
    }
}

final class ShadowMapInfo {
    let index: Int
    let texture: ITexture

    var isActual: Bool {
        return lock > 0
    }

    var description: String {
        "i:\(index) l:\(lock)"
    }

    fileprivate private(set) var needRemaker: Bool = false

    private var lock: Int = 0 {
        didSet {
            if lock < 0 {
                lock = 0
            }
            if lock <= 0 {
                needRemaker = true
            }
        }
    }

    init(index: Int, texture: ITexture) {
        self.index = index
        self.texture = texture
    }

    fileprivate func retain(lock: Int) {
        self.lock += lock
    }

    fileprivate func free() {
        lock = 0
    }

    fileprivate func loop() {
        lock -= 1
    }
}

extension Optional where Wrapped == LightInfo {
    func getBuffer(for device: MTLDevice) throws -> (MTLBuffer, Int)? {
        guard let self = self else {
            return nil
        }
        if let buffer = self.buffer, device === self.device {
            return (buffer, self.count)
        }
        self.lightInputCache.setNeedUpdate()
        let lights = self.lights.filter { !$0.isHidden }.compactMap { $0.light }
        let buffer = try self.lightInputCache.getBuffer(
            lights,
            device: device
        )
        self.buffer = buffer
        self.device = device
        self.count = lights.count
        return (buffer, lights.count)
    }
}

