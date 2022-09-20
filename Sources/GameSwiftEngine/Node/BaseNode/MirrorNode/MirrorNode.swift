import simd

/// It is expirement not use
public final class MirrorNode: Node, CameraNodeDelegate {
    let camera: CameraNode

    private let plane: Node = Node()
    private var planeInput: Sprite3DInput

    private var enableCounter: Int = 0

    public override init() {
        let x: GEFloat = 0.5
        let y: GEFloat = 0.5
        let z: GEFloat = 0
        self.planeInput = Sprite3DInput(
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
        planeInput.matireal = .mirror
        camera.projectionMatrix = perspectiveMatrix(aspectRatio: 1)
        camera.delegate = self
        self.plane.addSubnode(camera)
        self.plane.addRenderInput(planeInput)
        self.plane.rotate(to: .pi / 2, axis: .init(0, 1, 0))
        addSubnode(self.plane)
    }

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
//        camera.isActive = enableCounter % 4 == 0
//        enableCounter += 1
        guard camera.isActive, let scene = scene else {
            return
        }
        let normal = plane.absoluteTransform * vector_float4(0, 0, -1, 1) - plane.position.to4
        var cameraPosition = scene.mainCamera.position.to4 - plane.position.to4
        cameraPosition.y = 0
        let reflection = -cameraPosition - 2 * dot(-cameraPosition, normal) * normal
        let a1 = normalize(cameraPosition)
        let b1 = normalize(reflection)
        let angle = atan2(a1.x, a1.z) - atan2(b1.x, b1.z)
        //let angle = acos(dot(b1, a1)) / 2
        camera.rotate(to: -angle / 2, axis: .init(x: 0, y: 1, z: 0))
        // 𝑟=𝑑−2(𝑑⋅𝑛)𝑛
    }

    public func didUpdateRenderResault(_ camera: CameraNode) {
        planeInput.texture = camera.renderInfo.colorInfo.color
    }
}

extension vector_float4 {
    var xyz: vector_float3 {
        return .init(x, y, z)
    }
}

extension vector_float3 {
    var to4: vector_float4 {
        return .init(x, y, z, 1)
    }
}
