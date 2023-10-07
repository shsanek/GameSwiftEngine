public protocol ITexture: AnyObject {
    var identifier: ObjectIdentifier { get }

    var width: Int { get }
    var height: Int { get }
}

extension ITexture {
    public var identifier: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

extension ITexture {
    var metal: IMetalTexture? {
        self as? IMetalTexture
    }
}

public protocol ISourceTexture {
    var sourcePath: String? { get }
}
