import Foundation

public final class VoxelsSystemController {
    public private(set) var voxels: [VoxelCoordinate?: Voxel] = [:]
    public private(set) var groups: [UnvoxelGroupIdentifer: UnvoxelGroup] = [:]
    private var controllersForUpdate: [ObjectIdentifier: VoxelElementController] = [:]

    func addController(_ controller: VoxelElementController) {
        controller.updatePoints()
        addControllerInVoxels(controller)
        addControllerInGroups(controller)
        controller.delegate = self
    }

    func removeController(_ controller: VoxelElementController) {
        controller.delegate = nil
        removeControllerFromVoxels(controller)
        removeControllerFromGroups(controller)
    }

    func loop() {
        for controller in controllersForUpdate {
            guard controller.value.delegate === self else {
                return
            }
            controller.value.updateIfNeeded()
        }
        controllersForUpdate = [:]
    }

    public func getNodesGroup(for identifier: UnvoxelGroupIdentifer) -> [Node] {
        Array(getGroup(for: identifier).containers.values)
    }

    public func getGroup(for identifier: UnvoxelGroupIdentifer) -> UnvoxelGroup {
        guard let group = groups[identifier] else {
            let group = UnvoxelGroup()
            groups[identifier] = group
            return group
        }
        return group
    }

    public func filter(
        in coordinate: VoxelCoordinate,
        radius: GEFloat = 0,
        filter: (Node) -> Bool
    ) -> [Node] {
        var result: [Node] = []
        forEachVoxels(in: coordinate, radius: radius) {
            for container in $0.containers where filter(container.value) {
                result.append(container.value)
            }
        }
        return result
    }

    public func forEachVoxels(
        in coordinate: VoxelCoordinate,
        radius: GEFloat = 0,
        forEach: (Voxel) -> Void
    ) {
        forWithStopEachVoxels(in: coordinate, radius: radius) {
            forEach($0)
            return true
        }
    }

    public func forWithStopEachVoxels(
        in coordinate: VoxelCoordinate,
        radius: GEFloat = 0,
        forEach: (Voxel) -> Bool
    ) {
        let intRadius = Int(round(radius + 0.5001))
        //let radius = radius + 1
        for x in -intRadius...intRadius {
            for y in -intRadius...intRadius {
                for z in -intRadius...intRadius {
                    let coordinate = VoxelCoordinate(
                        x: coordinate.x + x,
                        y: coordinate.y + y,
                        z: coordinate.z + z
                    )
                    guard let voxel = voxels[coordinate] else {
                        continue
                    }
                    let result = forEach(voxel)
                    if !result {
                        return
                    }
                }
            }
        }
        guard let voxel = voxels[nil] else {
            return
        }
        _ = forEach(voxel)
    }

    private func removeControllerFromVoxels(_ controller: VoxelElementController) {
        guard let node = controller.node else {
            return
        }
        for oldPoint in controller.savedPoints {
            voxels[oldPoint]?.removeNode(node)
        }
        controller.savedPoints = []
    }

    private func addControllerInVoxels(_ controller: VoxelElementController) {
        guard let node = controller.node else {
            return
        }
        for oldPoint in controller.realPoints {
            if voxels[oldPoint] == nil {
                voxels[oldPoint] = .init()
            }
            voxels[oldPoint]?.addNode(node)
        }
        controller.savedPoints = controller.realPoints
    }

    private func removeControllerFromGroups(_ controller: VoxelElementController) {
        guard let node = controller.node else {
            return
        }
        for identifier in controller.savedGroups {
            groups[identifier]?.removeNode(node)
        }
        controller.savedGroups = []
    }

    private func addControllerInGroups(_ controller: VoxelElementController) {
        guard let node = controller.node else {
            return
        }
        for identifier in controller.groups {
            if groups[identifier] == nil {
                groups[identifier] = .init()
            }
            groups[identifier]?.addNode(node)
        }
        controller.savedGroups = controller.groups
    }
}

extension VoxelsSystemController: VoxelElementControllerDelegate {
    func didUpdatePoints(controller: VoxelElementController) {
        removeControllerFromVoxels(controller)
        addControllerInVoxels(controller)
    }


    func didUpdateGroups(controller: VoxelElementController) {
        removeControllerFromGroups(controller)
        addControllerInGroups(controller)
    }

    func setNeedUpdate(controller: VoxelElementController) {
        controllersForUpdate[ObjectIdentifier(controller)] = controller
    }
}
