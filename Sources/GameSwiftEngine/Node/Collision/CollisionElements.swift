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


extension DynamicCollisionElement {
    public struct Model: Codable {
        public var isActive: Bool = false
        public var radius: GEFloat = 0

        public init() {
        }

        public func fill(_ element: inout DynamicCollisionElement) {
            element.isActive = isActive
            element.radius = radius
        }

        public mutating func save(_ element: DynamicCollisionElement) {
            self.isActive = element.isActive
            self.radius = element.radius
        }
    }
}

extension StaticCollisionElement {
    public struct Model: Codable {
        public var isActive: Bool = false
        public var planes: [StaticCollisionPlane] = []

        public init() {
        }

        public func fill(_ element: inout StaticCollisionElement) {
            element.isActive = isActive
            element.planes = planes
        }

        public mutating func save(_ element: StaticCollisionElement) {
            self.isActive = element.isActive
            self.planes = element.planes
        }
    }
}
