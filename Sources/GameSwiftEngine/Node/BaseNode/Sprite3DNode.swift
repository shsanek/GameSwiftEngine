import simd


/// Simple 3d geometry object
public final class Sprite3DNode: Node {
    /// Current texture
    public var texture: ITexture? {
        didSet {
            encoder?.texture = texture
        }
    }
    private var encoder: Sprite3DInput?

    /// Create plane object
    /// - Parameters:
    ///   - texture: texture for object
    ///   - size: size plane
    public init(texture: ITexture?, size: Size) {
        super.init()
        reloadVertexs(Geometries.plane(with: size))
        self.texture = texture
    }


    /// Create plane object
    /// Use importers for generate vertexs example `ObjImporter`
    /// - Parameters:
    ///   - vertexs: vertexs
    ///   - size: size plane
    public init(
        vertexs: [Sprite3DInput.VertexInput],
        texture: Texture?
    ) {
        super.init()
        reloadVertexs(vertexs)
        self.texture = texture
    }

    /// Reload vertexs
    /// Use importers for generate vertexs example `ObjImporter`
    /// - Parameters:
    ///   - vertexs: vertexs
    ///   - size: size plane
    public func reloadVertexs(
        _ vertexs: [Sprite3DInput.VertexInput]
    ) {
        encoder.flatMap { removeRenderInputs($0) }
        let encoder = Sprite3DInput(
            texture: texture,
            vertexs: vertexs
        )
        self.encoder = encoder
        addRenderInput(encoder)
    }
}
