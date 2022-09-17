import MetalKit
import CoreGraphics

extension CGImage {
    func getMLTexture(device: MTLDevice, pixelFormat: MTLPixelFormat = .bgra8Unorm_srgb) throws -> MTLTexture? {
        let loader = MTKTextureLoader(device: device)
        let texture = try loader.newTexture(cgImage: self)
        return texture.makeTextureView(pixelFormat: pixelFormat)
    }
}

