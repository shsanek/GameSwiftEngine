import simd

final class CollisionController {
    private let voxelSystem: VoxelsSystemController

    init(voxelSystem: VoxelsSystemController) {
        self.voxelSystem = voxelSystem
    }

    func loop() {
        let group = voxelSystem.getGroup(for: .dynamicCollisionElement)
        for container in group.containers {
            proccese(for: container.value, group: group)
        }
    }

    private func proccese(
        for node: Node,
        group: UnvoxelGroup
    ) {
        var positionA = node.position.to4
        for container in group.containers {
            procceseDynamicCollision(nodeA: node, nodeB: container.value, positionA: &positionA)
        }
        procceseStaticCollision(
            position: positionA,
            dynamicNode: node
        )
    }

    private func procceseStaticCollision(
        position: vector_float4,
        dynamicNode: Node
    ) {
        var elements = [ObjectIdentifier: Node]()

        let radius = dynamicNode.dynamicCollisionElement.radius
        voxelSystem.forEachVoxels(
            in: .init(vector: position.xyz),
            radius: radius
        ) { voxel in
            for container in voxel.containers {
                guard container.value.staticCollisionElement.isActive else {
                    return
                }
                elements[container.key] = container.value
            }
        }

        var result = position
        var update = false
        for element in elements {
            for plane in element.value.staticCollisionElement.planes {
                let vector = absalutePositionColisionInPlane(
                    position: result,
                    radius: radius,
                    planeSize: plane.size,
                    planeTransform: matrix_multiply(element.value.absoluteTransform, plane.transform)
                )
                if let vector = vector {
                    result = vector
                    update = true
                }
            }
        }
        guard update else {
            return
        }
        let delta = result - position
        dynamicNode.move(on: .init(x: delta.x, y: delta.y, z: delta.z))
    }

    private func procceseDynamicCollision(
        nodeA: Node,
        nodeB: Node,
        positionA: inout vector_float4
    ) {
        guard nodeA !== nodeB else {
            return
        }
        let radiusA = nodeA.dynamicCollisionElement.radius
        let radiusB = nodeB.dynamicCollisionElement.radius

        let vectoreMove = calculateDynamicVectoreMove(
            positionA: positionA,
            positionB: nodeB.position.to4,
            radiusA: radiusA,
            radiusB: radiusB
        )
        positionA += vectoreMove.to4

        nodeA.move(on: vectoreMove)
        nodeB.move(on: -vectoreMove)
    }

    private func calculateDynamicVectoreMove(
        positionA: vector_float4,
        positionB: vector_float4,
        radiusA: GEFloat,
        radiusB: GEFloat
    ) -> vector_float3 {
        let delta = positionA - positionB
        let move = (length(delta) - (radiusB + radiusA)) / 2
        guard move < 0 else {
            return .zero
        }
        let norm = normalize(delta)
        let vectoreMove = norm * move

        return vectoreMove.xyz
    }
}
