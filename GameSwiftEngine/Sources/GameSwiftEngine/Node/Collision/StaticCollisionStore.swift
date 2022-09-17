import simd

struct MapCordinate: Hashable {
    let x: Int
    let y: Int
}

final class CollisionController {

    private(set) var staticProviders: [MapCordinate?: [StaticCollisionProvider]] = [:]
    private(set) var dynamicProviders: [DynamicCollisionProvider] = []

    func addProvider(
        _ provider: StaticCollisionProvider,
        in MapCordinate: MapCordinate? = nil
    ) {
        if staticProviders[MapCordinate] == nil {
            staticProviders[MapCordinate] = []
        }
        staticProviders[MapCordinate]?.append(provider)
        provider.isActive = true
    }

    func removeProvider(_ provider: StaticCollisionProvider) {
        for key in staticProviders.keys {
            staticProviders[key]?.removeAll(where: { $0 === provider })
        }
        provider.isActive = false
    }

    func addProvider(
        _ provider: DynamicCollisionProvider
    ) {
        dynamicProviders.append(provider)
        provider.isActive = true
    }

    func removeProvider(
        _ provider: DynamicCollisionProvider
    ) {
        dynamicProviders.removeAll(where: { $0 === provider })
        provider.isActive = false
    }

    func update() {
        for container in staticProviders {
            for provider in container.value {
                provider.node?.updateStaticCollisionMapCordinateIfNeeded()
            }
        }
        for provider in dynamicProviders {
            proccesedProvider(provider)
        }
    }

    private func proccesedProvider(
        _ current: DynamicCollisionProvider
    ) {
        guard let node = current.node, let radiusA = node.dynamicCollisionRadius else {
            return
        }
        var positionA = matrix_multiply(node.absoluteTransform, .init(0, 0, 0, 1))
        for provider in dynamicProviders {
            guard provider !== current, let currentNode = provider.node  else {
                continue
            }
            guard let radiusB = currentNode.dynamicCollisionRadius else {
                continue
            }
            let positionB = matrix_multiply(currentNode.absoluteTransform, .init(0, 0, 0, 1))
            let delta = positionA - positionB
            let move = (length(delta) - (radiusB + radiusA)) / 2
            guard move < 0 else {
                continue
            }
            let norm = normalize(delta)

            let vectoreMove = norm * move
            positionA += vectoreMove
            node.move(on: .init(x: vectoreMove.x, y: vectoreMove.y, z: vectoreMove.z))
            currentNode.move(on: .init(x: -vectoreMove.x, y: -vectoreMove.y, z: -vectoreMove.z))
        }
        let staticMove = getStaticAntiCollisionVector(
            for: positionA,
            radius: radiusA,
            transfrom: node.absoluteTransform
        )
        if let position = staticMove {
            let delta = position - positionA
            node.move(on: .init(x: delta.x, y: delta.y, z: delta.z))
        }
    }

    private func getStaticAntiCollisionVector(
        for position: vector_float4,
        radius: Float,
        transfrom: matrix_float4x4
    ) -> vector_float4? {
        let baseRasius = radius
        let radius = radius + 1
        var providers = [ObjectIdentifier: StaticCollisionProvider]()

        let positionX = Int(position.x)
        let positionY = Int(position.z)

        for i in Int(-radius)...Int(radius) {
            for j in Int(-radius)...Int(radius) {
                for provider in self.staticProviders[.init(x: positionX + i, y: positionY + j)] ?? [] {
                    providers[ObjectIdentifier(provider)] = provider
                }
            }
        }
        for provider in self.staticProviders[nil] ?? [] {
            providers[ObjectIdentifier(provider)] = provider
        }

        var result = position
        var update = false
        for provider in providers {
            guard let node = provider.value.node else {
                continue
            }
            for plane in provider.value.planes {
                let vector = absalutePositionColisionInPlane(
                    position: result,
                    radius: baseRasius,
                    planeSize: plane.size,
                    planeTransform: matrix_multiply(node.absoluteTransform, plane.transform)
                )
                if let vector = vector {
                    result = vector
                    update = true
                }
            }
        }
        if update {
            return result
        }
        return nil
    }
}
