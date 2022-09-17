import simd

public final class Object3DNode: Node {
    public var texture: Texture? {
        didSet {
            encoder.texture = texture
        }
    }
    public var frameCount: Int {
        return object.frame.count
    }

    private let encoder: Sprite3DInput
    private let object: InterQuakeImporter.Object

    private let baseFrame: [matrix_float4x4]
    private(set) var bones: [matrix_float4x4] = [] {
        didSet {
            if bones == oldValue {
                return
            }
            self.encoder.bones.values = [.init(1)] + (bones.enumerated().map { $0.element * baseFrame[$0.offset] })
        }
    }

    private var toBones: [matrix_float4x4] = []
    private var fromBones: [matrix_float4x4] = []
    private var progress: Float? {
        didSet {
            if oldValue == progress {
                return
            }
            if let progress = progress {
                updateProgress(progress)
            }
        }
    }

    public init(object: InterQuakeImporter.Object, texture: Texture? = nil) {
        self.object = object
        self.texture = texture
        self.encoder = Sprite3DInput(texture: texture, vertexs: object.getVertexs())
        self.baseFrame = object.getBoneTransform().map { $0.transform.inverse }
        super.init()
        addRenderInputs(encoder)
        self.encoder.vertexIndexs.values = object.getIndexs()
    }
    
    public func setFrame(_ frame: Int) {
        self.bones = object.getBoneTransform(with: frame).map { $0.transform }
        self.toBones = self.bones
        self.fromBones = self.bones
    }

    func frameTransition(from fromFrame: Int, to toFrame: Int, startProgress: Float = 0) {
        self.toBones = object.getBoneTransform(with: toFrame).map { $0.transform }
        self.fromBones = object.getBoneTransform(with: fromFrame).map { $0.transform }
        self.progress = nil
        self.progress = startProgress
    }

    func frameTransition(from bones: [matrix_float4x4], to toFrame: Int, startProgress: Float = 0) {
        self.fromBones = bones
        self.toBones = object.getBoneTransform(with: toFrame).map { $0.transform }
        self.progress = nil
        self.progress = startProgress
    }

    func setTransitionProgress(_ progress: Float) {
        let progress = max(min(progress, 1), 0)
        self.progress = progress
    }

    private func updateProgress(_ progress: Float) {
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
