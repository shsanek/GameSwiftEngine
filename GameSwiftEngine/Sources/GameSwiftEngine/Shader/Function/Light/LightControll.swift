import simd
import MetalKit

final class LightController {
    private(set) var lightInfo = LightInfo()
    private(set) var lightNodes: [LightNode] = []

    func addLight(_ light: LightNode) {
        lightNodes.append(light)
        lightInfo.lights.append(light.provider)
    }

    func removeLight(_ light: LightNode) {
        lightNodes.removeAll(where: { $0 === light })
        lightInfo.lights.removeAll(where: { $0 === light.provider })
    }

    func calculatePosition() {
        lightInfo.buffer = nil
        lightNodes.forEach { $0.calculate() }
    }
}
