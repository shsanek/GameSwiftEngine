import simd

public class CameraNode: Node {
    public weak var delegate: CameraNodeDelegate?

    public var projectionMatrixContainer: ProjectionMatrixContainer = .updatable { size in
        perspectiveMatrix(aspectRatio: GEFloat(size.width / size.height))
    }

    /// If the camera is activated, a render will be performed
    /// Ignore for main camera
    public var isActive: Bool = true

    /// RenderInfo
    /// Ignore for main camera
    public var renderInfo: RenderInfo = .init()

    /// Projection matrix for render
    private(set) var projectionMatrix: matrix_float4x4 = .init(1)

    public override init() {
        super.init()
    }

    /// Ignore for main camera
    /// Called after the end of the render with updating renderInfo
    open func didRender() {
        delegate?.didUpdateRenderResault(self)
    }

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        // бля ну это кривое говно
        projectionMatrix = projectionMatrixContainer.matrix(for: size)
    }

    public override func didMoveSceene(oldSceene: SceneNode?, scene: SceneNode?) {
        super.didMoveSceene(oldSceene: oldSceene, scene: scene)
        oldSceene?.camers.removeAll(where: { $0 === self })
        scene?.camers.append(self)
    }
}

public class EditorCameraNode: CameraNode {
    private let input = Grid3DInput()

    public var gridScale: Float = 1 {
        didSet {
            input.scale = 1 / gridScale
        }
    }

    public override init() {
        super.init()
        addRenderInput(input)
    }
}

public protocol CameraNodeDelegate: AnyObject {
    /// Called after the end of the render with updating renderInfo
    func didUpdateRenderResault(_ camera: CameraNode)
}

public enum ProjectionMatrixContainer {
    case constant(_ matrix: matrix_float4x4)
    case updatable(_ block: (Size) -> matrix_float4x4)

    public func matrix(for screenSize: Size) -> matrix_float4x4 {
        switch self {
        case .constant(let matrix):
            return matrix
        case .updatable(let block):
            return block(screenSize)
        }
    }
}
