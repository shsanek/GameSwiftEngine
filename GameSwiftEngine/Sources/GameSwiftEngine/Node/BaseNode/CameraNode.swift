import simd

public class CameraNode: Node {
    public weak var delegate: CameraNodeDelegate?

    public var projectionMatrix: matrix_float4x4 = .init(1)
    public var isActive: Bool = true

    // ignore for main camera
    public var renderInfo: RenderInfo = .init()

    public override init() {
        super.init()
    }

    // ignore for main camera
    open func didRender() {
        delegate?.didUpdateRenderResault(self)
    }

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        projectionMatrix = perspectiveMatrix(aspectRatio: GEFloat(size.width / size.height))
    }

    public override func didMoveSceene(oldSceene: SceeneNode?, sceene: SceeneNode?) {
        oldSceene?.camers.removeAll(where: { $0 === self })
        sceene?.camers.append(self)
    }
}

public protocol CameraNodeDelegate: AnyObject {
    func didUpdateRenderResault(_ camera: CameraNode)
}
