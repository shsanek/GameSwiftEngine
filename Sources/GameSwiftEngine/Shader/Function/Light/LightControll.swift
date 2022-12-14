import simd

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
        lightInfo.loop()
        lightNodes.forEach { $0.calculate() }
    }

    func getTextureForShadow(lock: Int) -> ShadowMapInfo? {
        lightInfo.getTextureForShadow(lock: lock)
    }
}
