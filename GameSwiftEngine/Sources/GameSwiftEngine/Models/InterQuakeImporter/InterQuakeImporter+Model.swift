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

    struct Vertex {
        public struct Binding {
            let index: Int
            let power: Float
        }
        public let position: vector_float3
        public let uv: vector_float2?
        public let normal: vector_float3?
        public let binding: [Binding]
    }

    struct Poligon {
        public let a: Int
        public let b: Int
        public let c: Int
    }

    struct Frame {
        public let bones: [Bone]
    }

    struct Object {
        public let poligons: [Poligon]
        public let frame: [Frame]
        public let vertex: [Vertex]
        public let bone: [Bone]
    }
}
