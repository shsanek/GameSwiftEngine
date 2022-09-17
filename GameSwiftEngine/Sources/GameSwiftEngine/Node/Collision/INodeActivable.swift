public protocol INodeActivable: Node {
    func updateActivablePositionIfNeeded()

    func active()
}

public extension INodeActivable {
    func active() { }
}

import simd

final class NodeActivableController {
    private var map: [MapCordinate?: [INodeActivable]] = [:]

    func addActivable(in cordinate: MapCordinate?, _ activable: INodeActivable) {
        if map[cordinate] == nil {
            map[cordinate] = []
        }
        map[cordinate]?.append(activable)
    }

    func removeActivable(_ activable: INodeActivable) {
        for key in map.keys {
            map[key]?.removeAll(where: { $0 === activable })
        }
    }

    func getActivableNode(
        in position: vector_float3,
        lng: Float = 1,
        direction: vector_float3,
        angle: Float
    ) -> [INodeActivable] {
        for container in map {
            for node in container.value {
                node.updateActivablePositionIfNeeded()
            }
        }
        let radius = lng + 1
        let positionX = Int(position.x)
        let positionY = Int(position.z)

        let count = Int(radius)

        var result: [INodeActivable] = []

        for i in -count...count {
            for j in -count...count {
                let nodes = (map[.init(x: positionX + i, y: positionY + j)] ?? [])
                result.append(contentsOf: nodes)
            }
        }
        return result
            .map { (lng: length($0.position - position), node: $0) }
            .filter { $0.lng < lng }
            .filter { container in
                let direction = normalize(direction)
                let delta = container.node.position - position
                return acos(dot(normalize(direction), normalize(-delta))) < angle
            }
            .sorted(by: { $0.lng < $1.lng })
            .map { $0.node }
    }
}
