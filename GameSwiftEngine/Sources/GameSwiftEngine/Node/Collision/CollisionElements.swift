extension UnvoxelGroupIdentifer {
    static var dynamicCollisionElement = UnvoxelGroupIdentifer(identifier: "DynamicCollisionElement")
}

public struct DynamicCollisionElement {
    public var isActive: Bool = false {
        didSet {
            guard isActive != oldValue else {
                return
            }
            if isActive {
                voxelElementController
                    .groups
                    .insert(.dynamicCollisionElement)
            } else {
                voxelElementController
                    .groups
                    .remove(.dynamicCollisionElement)
            }
        }
    }
    public var radius: GEFloat = 1

    let voxelElementController: VoxelElementController

    init(voxelElementController: VoxelElementController) {
        self.voxelElementController = voxelElementController
    }
}

public struct StaticCollisionElement {
    public var isActive: Bool = false
    public var planes: [StaticCollisionPlane] = []
}
