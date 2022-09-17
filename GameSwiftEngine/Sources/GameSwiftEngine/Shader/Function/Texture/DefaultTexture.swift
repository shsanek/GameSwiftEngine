import MetalKit

struct DefaultTexture: ITexture {
    let width: Int
    let height: Int
    let texture: MTLTexture?

    func getMLTexture(device: MTLDevice) -> MTLTexture? {
        return texture
    }
}
