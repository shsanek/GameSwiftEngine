/// Root node for sceene
/// there can only be one for the hierarchy
open class SceeneNode: Node {

    let lightController = LightController()
    lazy var collisionController = CollisionController(voxelSystem: voxelsSystemController)

    /// VoxelsSystemController
    public let voxelsSystemController = VoxelsSystemController()

    public override var sceene: SceeneNode? {
        self
    }

    /// Main Camera - render from it will be displayed
    public var mainCamera = CameraNode()

    /// All camers in hierarchy
    public internal(set) var camers: [CameraNode] = []

    public override init() {
        super.init()
        addSubnode(mainCamera)
    }
}
