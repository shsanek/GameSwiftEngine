import simd

extension VoxelsSystemController {
    func getActivableNodes(
        in position: vector_float3,
        lng: GEFloat = 1,
        direction: vector_float3,
        angle: GEFloat
    ) -> [Node] {
        self.filter(in: .init(vector: position), radius: lng) { node in
            let lng = length(node.position - position)
            let direction = normalize(direction)
            let delta = node.position - position
            return lng < lng && acos(dot(normalize(direction), normalize(-delta))) < angle
        }.sorted(by: { length($0.position - position) < length($1.position - position) })
    }
}
