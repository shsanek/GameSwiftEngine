import simd

public class CameraNode: Node {
    public var projectionMatrix: matrix_float4x4 = .init(1)
    public var isActive: Bool = true

    public override init() {
        super.init()
    }

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        projectionMatrix = perspectiveMatrix(aspectRatio: Float(size.width / size.height))
    }
}
