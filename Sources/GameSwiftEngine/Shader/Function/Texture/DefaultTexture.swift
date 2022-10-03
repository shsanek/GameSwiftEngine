import MetalKit

final class DefaultTexture: ITexture, IMetalTexture {
    let width: Int
    let height: Int
    let texture: MTLTexture?

    init(width: Int, height: Int, texture: MTLTexture?) {
        self.width = width
        self.height = height
        self.texture = texture
    }

    func getMLTexture(device: MTLDevice) -> MTLTexture? {
        return texture
    }
}
