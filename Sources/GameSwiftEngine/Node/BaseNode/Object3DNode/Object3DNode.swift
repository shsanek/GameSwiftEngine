import simd

/// Node for InterQuakeImporter.Object
/// Supported bone animation
public final class Object3DNode: Node {
    public override var typeIdentifier: String { "Object3DNode" }

    /// Current texture
    public var texture: ITexture? {
        didSet {
            encoder?.texture = texture
        }
    }

    /// Number of animation frames
    public var frameCount: Int {
        return object?.frame.count ?? 0
    }

    private var encoder: Sprite3DInput?
    private var object: InterQuakeImporter.Object?
    private(set) var geometry: Object3DNodeGeometrySource

    private var baseFrame: [matrix_float4x4]
    private(set) var bones: [matrix_float4x4] = [] {
        didSet {
            if bones == oldValue {
                return
            }
            self.encoder?.bones.values = [.init(1)] + (bones.enumerated().map { $0.element * baseFrame[$0.offset] })
        }
    }

    private var toBones: [matrix_float4x4] = []
    private var fromBones: [matrix_float4x4] = []
    private var progress: GEFloat? {
        didSet {
            if oldValue == progress {
                return
            }
            if let progress = progress {
                updateProgress(progress)
            }
        }
    }

    /// Create node
    /// Use ObjImporter for load Object
    /// - Parameters:
    ///   - object: Geometry
    ///   - texture: texture
    public init(source: Object3DNodeGeometrySource, texture: ITexture? = nil) {
        self.geometry = source
        self.baseFrame = []
        super.init()
        self.texture = texture
        self.reload(source)
    }

    /// Set frame (not animation)
    /// For animation use `NodeAnimation.updateFrame`
    /// - Parameter frame: frame number
    public func setFrame(_ frame: Int) {
        self.bones = object?.getBoneTransform(with: frame).map { $0.transform } ?? []
        self.toBones = self.bones
        self.fromBones = self.bones
    }

    public func reload(_ source: Object3DNodeGeometrySource) {
        let object = source.object
        encoder.flatMap { removeRenderInputs($0) }
        self.object = object
        let encoder = Sprite3DInput(texture: self.texture, vertexs: object?.getVertexs() ?? [])
        self.baseFrame = object?.getBoneTransform().map { $0.transform.inverse } ?? []
        addRenderInput(encoder)
        encoder.texture = self.texture
        self.encoder = encoder
        self.encoder?.vertexs.values = object?.getVertexs() ?? []
        self.geometry = source
    }

    func frameTransition(from fromFrame: Int, to toFrame: Int, startProgress: GEFloat = 0) {
        self.toBones = object?.getBoneTransform(with: toFrame).map { $0.transform } ?? []
        self.fromBones = object?.getBoneTransform(with: fromFrame).map { $0.transform } ?? []
        self.progress = nil
        self.progress = startProgress
    }

    func frameTransition(from bones: [matrix_float4x4], to toFrame: Int, startProgress: GEFloat = 0) {
        self.fromBones = bones
        self.toBones = object?.getBoneTransform(with: toFrame).map { $0.transform } ?? []
        self.progress = nil
        self.progress = startProgress
    }

    func setTransitionProgress(_ progress: GEFloat) {
        let progress = max(min(progress, 1), 0)
        self.progress = progress
    }

    private func updateProgress(_ progress: GEFloat) {
        guard fromBones.count == toBones.count else {
            assertionFailure("incorect count in bones")
            return
        }
        var result = [matrix_float4x4]()
        for index in 0..<fromBones.count {
            result.append(fromBones[index] * (1 - progress) + toBones[index] * progress)
        }
        bones = result
    }
}
