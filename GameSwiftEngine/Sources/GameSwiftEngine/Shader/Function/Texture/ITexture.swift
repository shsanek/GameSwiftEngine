public protocol ITexture {
    var width: Int { get }
    var height: Int { get }
}

extension ITexture {
    var metal: IMetalTexture? {
        self as? IMetalTexture
    }
}
