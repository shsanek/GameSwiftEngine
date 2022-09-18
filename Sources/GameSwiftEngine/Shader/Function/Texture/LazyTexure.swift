import MetalKit

final class LazyTexure: ITexture, IMetalTexture {
    let width: Int
    let height: Int

    private let descriptor: MTLTextureDescriptor

    init(descriptor: MTLTextureDescriptor, size: Size) {
        self.descriptor = descriptor
        self.width = Int(size.width)
        self.height = Int(size.height)
    }

    // METAL

    var texture: MTLTexture?

    func getMLTexture(device: MTLDevice) -> MTLTexture? {
        self.texture = self.texture ?? device.makeTexture(descriptor: descriptor)
        return texture
    }
}
