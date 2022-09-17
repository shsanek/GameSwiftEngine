open class SceeneNode: Node {
    let lightController = LightController()
    let collisionController = CollisionController()
    let activableController = NodeActivableController()

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
