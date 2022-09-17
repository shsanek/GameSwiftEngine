import MetalKit

public protocol ITexture {
    var width: Int { get }
    var height: Int { get }
    func getMLTexture(device: MTLDevice) -> MTLTexture?
}
