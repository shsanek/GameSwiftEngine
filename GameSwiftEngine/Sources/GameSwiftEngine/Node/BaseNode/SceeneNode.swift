open class SceeneNode: Node {
    let lightController = LightController()
    lazy var collisionController = CollisionController(voxelSystem: voxelsSystemController)
    public let voxelsSystemController = VoxelsSystemController()

    public override var sceene: SceeneNode? {
        self
    }

    public var mainCamera = CameraNode()
    public internal(set) var camers: [CameraNode] = []

    public override init() {
        super.init()
        addSubnode(mainCamera)
    }
}
