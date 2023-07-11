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
    private var Sprite3DNodeGeometrySource: Sprite3DNodeGeometrySource?

    /// Create plane object
    /// - Parameters:
    ///   - texture: texture for object
    ///   - size: size plane
    public init(texture: ITexture?, size: Size) {
        super.init()
        reloadVertexs(.plane(size))
        self.texture = texture
    }

    /// Create plane object
    /// Use importers for generate vertexs example `ObjImporter`
    /// - Parameters:
    ///   - vertexs: vertexs
    ///   - size: size plane
    public init(
        geometry: Sprite3DNodeGeometrySource,
        texture: Texture?
    ) {
        super.init()
        reloadVertexs(geometry)
        self.texture = texture
    }

    /// Reload vertexs
    /// Use importers for generate vertexs example `ObjImporter`
    /// - Parameters:
    ///   - vertexs: vertexs
    ///   - size: size plane
    public func reloadVertexs(
        _ geometry: Sprite3DNodeGeometrySource
    ) {
        encoder.flatMap { removeRenderInputs($0) }
        guard let vertex = geometry.onlyVertexs else {
            return
        }
        let encoder = Sprite3DInput(
            texture: texture,
            vertexs: vertex
        )
        self.Sprite3DNodeGeometrySource = geometry.light
        self.encoder = encoder
        addRenderInput(encoder)
    }

    public func getSprite3DNodeGeometrySource() -> Sprite3DNodeGeometrySource {
        switch Sprite3DNodeGeometrySource {
        case .vertexs:
            return encoder.flatMap { .vertexs($0.vertexs.values) } ?? .empty
        default:
            return Sprite3DNodeGeometrySource ?? .empty
        }
    }
}
