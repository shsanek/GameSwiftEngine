import simd

protocol VoxelElementControllerDelegate: AnyObject {
    func setNeedUpdate(controller: VoxelElementController)
    func didUpdatePoints(controller: VoxelElementController)
    func didUpdateGroups(controller: VoxelElementController)
}

public final class VoxelElementController {
    public var groups: Set<UnvoxelGroupIdentifer> = [] {
        didSet {
            guard groups != oldValue else {
                return
            }
            setNeedGroupsUpdate()
        }
    }

    /// points in local coordinats
    public var points: Set<VoxelCoordinate?> = [] {
        didSet {
            guard points != oldValue else {
                return
            }
            setNeedPointsUpdate()
        }
    }

    weak var delegate: VoxelElementControllerDelegate?

    /// real coordinate with object transform
    var realPoints: Set<VoxelCoordinate?> = [] {
        didSet {
            guard self.realPoints != oldValue else {
                return
            }
            delegate?.didUpdatePoints(controller: self)
        }
    }

    /// last groups saved in VoxelsSystemController
    var savedGroups: Set<UnvoxelGroupIdentifer> = []

    /// last points saved in VoxelsSystemController
    var savedPoints: Set<VoxelCoordinate?> = []

    weak var node: Node?

    private var isNeedPointsUpdate: Bool = false
    private var isNeedGroupsUpdate: Bool = false
    private var isLockUpdate: Bool = false

    init(node: Node) {
        self.node = node
    }

    public func lockNeedUpdate(_ action: () -> Void) {
        isLockUpdate = true
        action()
        isLockUpdate = false
    }

    public func setNeedPointsUpdate() {
        guard !isNeedPointsUpdate && !isLockUpdate else {
            return
        }
        self.isNeedPointsUpdate = true
        delegate?.setNeedUpdate(controller: self)
    }

    public func updateIfNeeded() {
        if isNeedPointsUpdate {
            updatePoints()
        }
        if isNeedGroupsUpdate {
            updateGroups()
        }
    }

    public func updateGroups() {
        delegate?.didUpdateGroups(controller: self)
        isNeedPointsUpdate = false
    }

    public func updatePoints() {
        updateRealVoxelsPoints()
        isNeedPointsUpdate = false
    }

    private func updateRealVoxelsPoints() {
        guard let node = node else { return }
        var result = Set<VoxelCoordinate?>()
        for point in points {
            let real = point.flatMap { VoxelCoordinate(vector: (node.absoluteTransform * $0.toVector.to4).xyz) }
            result.insert(real)
        }
        realPoints = result
    }

    private func setNeedGroupsUpdate() {
        guard !isNeedPointsUpdate else {
            return
        }
        self.isNeedPointsUpdate = true
        delegate?.setNeedUpdate(controller: self)
    }
}
