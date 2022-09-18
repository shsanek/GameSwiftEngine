import simd

public extension InterQuakeImporter {
    struct BoneTransform {
        public let translate: vector_float3
        public let quaternion: vector_float4
        public let scale: vector_float3
    }

    struct Bone {
        public let transform: BoneTransform
        public let parent: Int
        public let name: String
    }

    /// Vertex
    struct Vertex {
        /// Info of bone
        public struct Binding {
            let index: Int
            let power: GEFloat
        }

        /// Position in space
        public let position: vector_float3

        /// Texture
        public let uv: vector_float2?
        public let normal: vector_float3?
        public let binding: [Binding]
    }

    /// Triangle polygon
    struct Poligon {
        public let a: Int
        public let b: Int
        public let c: Int
    }

    /// Animation frame (pose)
    struct Frame {
        public let bones: [Bone]
    }

    /// QIE model, contaned geometry, uv and animation info
    /// dV = Sum(binding { bone.matrix \* originalBone.matrix \* V \* width })
    struct Object {
        public let poligons: [Poligon]
        public let frame: [Frame]
        public let vertex: [Vertex]
        public let bone: [Bone]
    }
}
