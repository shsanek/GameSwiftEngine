import simd

/// It is expirement not use
public final class MirrorNode: Node, CameraNodeDelegate {
    let camera: CameraNode

    private let plane: Node = Node()
    private var planeInput: Sprite3DInput

    private var enableCounter: Int = 0

    public override init() {

        self.planeInput = Sprite3DInput(
            texture: nil,
            vertexs: GeometryContainer.plane.vertexes
        )
        self.planeInput.vertexIndexs.values = GeometryContainer.plane.indexes
        camera = CameraNode()
        super.init()
        planeInput.material = .mirror
        camera.projectionMatrixContainer = .constant(perspectiveMatrix(aspectRatio: 1))
        camera.delegate = self
        self.addSubnode(camera)
        self.plane.addRenderInput(planeInput)
        //camera.rotate(to: -.pi / 2, axis: .init(0, 1, 0))
        self.plane.rotate(to: -.pi / 2, axis: .init(0, 1, 0))
        addSubnode(self.plane)

//        let node = Node()
//        let input = Sprite3DInput(
//            texture: Texture.load(in: "CONCRETE_1B"),
//            vertexs: GeometryContainer.plane.vertexes
//        )
//        node.addRenderInput(input)
//        planeInput.vertexIndexs.values = GeometryContainer.plane.indexes
//        camera.addSubnode(node)
    }

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
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
        camera.rotate(to: angle, axis: .init(x: 0, y: 1, z: 0))
    }

    public func didUpdateRenderResault(_ camera: CameraNode) {
        planeInput.texture = camera.renderInfo.colorInfo.color
    }
}

public final class Plane: Node, ITexturable {
    public var texture: ITexture? {
        didSet {
            self.planeInput.texture = texture
        }
    }
    public var planeInput: Sprite3DInput = {
        let input = Sprite3DInput(texture: nil, vertexs: GeometryContainer.plane.vertexes)
        input.vertexIndexs.values = GeometryContainer.plane.indexes
        return input
    }()

    public override init() {
        super.init()
        addRenderInput(planeInput)
    }
}

extension GeometryContainer {
    static let plane: GeometryContainer = {
        let x: GEFloat = 0.5
        let y: GEFloat = 0.5
        let z: GEFloat = 0
        return .init(
            vertexes: [
                .init(position: .init(x: -x, y: y, z: -z), uv: .init(0, 0)),
                .init(position: .init(x: x, y: y, z: -z), uv: .init(1, 0)),
                .init(position: .init(x: x, y: -y, z: -z), uv: .init(1, 1)),
                .init(position: .init(x: -x, y: -y, z: -z), uv: .init(0, 1)),
            ],
            indexes: [0, 1, 2, 2, 3, 0],
            bonesCount: 0
        )
    }()
}
