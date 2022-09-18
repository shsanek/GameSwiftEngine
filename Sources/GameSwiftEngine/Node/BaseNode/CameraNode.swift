import simd

public class CameraNode: Node {
    public weak var delegate: CameraNodeDelegate?

    /// Projection matrix for render
    public var projectionMatrix: matrix_float4x4 = .init(1)

    /// If the camera is activated, a render will be performed
    /// Ignore for main camera
    public var isActive: Bool = true

    /// RenderInfo
    /// Ignore for main camera
    public var renderInfo: RenderInfo = .init()

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
        projectionMatrix = perspectiveMatrix(aspectRatio: GEFloat(size.width / size.height))
    }

    public override func didMoveSceene(oldSceene: SceeneNode?, sceene: SceeneNode?) {
        super.didMoveSceene(oldSceene: oldSceene, sceene: sceene)
        oldSceene?.camers.removeAll(where: { $0 === self })
        sceene?.camers.append(self)
    }
}

public protocol CameraNodeDelegate: AnyObject {
    /// Called after the end of the render with updating renderInfo
    func didUpdateRenderResault(_ camera: CameraNode)
}
