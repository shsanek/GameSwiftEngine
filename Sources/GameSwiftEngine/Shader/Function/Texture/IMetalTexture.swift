import MetalKit

protocol IMetalTexture {
    func getMLTexture(device: MTLDevice) -> MTLTexture?
}
