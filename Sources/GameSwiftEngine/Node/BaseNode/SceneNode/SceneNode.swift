/// Root node for scene
/// there can only be one for the hierarchy
open class SceneNode: Node {
    /// VoxelsSystemController
    public let voxelsSystemController = VoxelsSystemController()
    public let objects3DArraysManager = Objects3DArraysManager()

    public override var scene: SceneNode? {
        self
    }

    /// Main Camera - render from it will be displayed
    public var mainCamera = CameraNode()

    /// All camers in hierarchy
    public internal(set) var camers: [CameraNode] = []

    let lightController = LightController()
    lazy var collisionController = CollisionController(voxelSystem: voxelsSystemController)
    let renderPool = NodePool()
    let updatePool = NodePool()

    public override init() {
        super.init()
        addSubnode(mainCamera)
    }
}
