import simd

public final class MirrorNode: Node, CameraNodeDelegate {
    let plane: Sprite3DInput
    let camera: CameraNode

    private var enableCounter: Int = 0

    public override init() {
        let x: Float = 0.5
        let y: Float = 0.5
        let z: Float = 0
        plane = Sprite3DInput(
            texture: nil,
            vertexs: [
                .init(position: .init(x: -x, y: -y, z: -z), uv: .init(0, 1)),
                .init(position: .init(x: -x, y: y, z: -z), uv: .init(0, 0)),
                .init(position: .init(x: x, y: y, z: -z), uv: .init(1, 0)),

                .init(position: .init(x: -x, y: -y, z: -z), uv: .init(0, 1)),
                .init(position: .init(x: x, y: -y, z: -z), uv: .init(1, 1)),
                .init(position: .init(x: x, y: y, z: -z), uv: .init(1, 0))
            ]
        )
        camera = CameraNode()
        super.init()
        camera.projectionMatrix = perspectiveMatrix(aspectRatio: 1)
        camera.delegate = self
        addRenderInputs(plane)
        addSubnode(camera)

        rotate(to: .pi / 2, axis: .init(0, 1, 0))
    }

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        camera.isActive = enableCounter % 4 == 0
        enableCounter += 1
    }

    public func didUpdateRenderResault(_ camera: CameraNode) {
        plane.texture = camera.renderInfo.colorInfo.color
    }
}
