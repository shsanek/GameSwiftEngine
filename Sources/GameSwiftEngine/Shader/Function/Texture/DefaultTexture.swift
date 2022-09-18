import MetalKit

struct DefaultTexture: ITexture, IMetalTexture {
    let width: Int
    let height: Int
    let texture: MTLTexture?

    func getMLTexture(device: MTLDevice) -> MTLTexture? {
        return texture
    }
}
