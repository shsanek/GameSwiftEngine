import simd

public struct VoxelCoordinate: Hashable {
    public var x: Int = 0
    public var y: Int = 0
    public var z: Int = 0

    public init(x: Int = 0, y: Int = 0, z: Int = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(vector: vector_float3) {
        self.x = Int(round(vector.x))
        self.y = Int(round(vector.y))
        self.z = Int(round(vector.z))
    }
}

extension VoxelCoordinate {
    var toVector: vector_float3 {
        .init(x: GEFloat(x), y: GEFloat(y), z: GEFloat(z))
    }
}
