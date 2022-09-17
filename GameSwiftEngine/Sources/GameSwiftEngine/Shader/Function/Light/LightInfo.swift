import MetalKit
import simd

final class LightInfo {
    struct Light: RawEncodable {
        var position: vector_float3
        var color: vector_float3 = .one
        var power: Float = 1
        var ceilStep: Float = -1
        var direction: vector_float3 = .init(x: 0, y: 0, z: 1)
        var angle: Float = .pi
        var attenuationAngle: Float = -1
    }

    let lightInputCache = MetalBufferCache()
    var lights: [LightProvider] = []

    var buffer: MTLBuffer? = nil
    weak var device: MTLDevice? = nil
    var count: Int = 0
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
