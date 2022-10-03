import Foundation
import simd

extension Node {
    public struct Model: Codable {
        public var node: NodeModel = .init()

        public init(node: NodeModel = .init()) {
            self.node = node
        }
    }

    public struct NodeModel: Codable {
        public var isHidden: Bool = false
        public var firstMatrix: matrix_float4x4 = .init(1)
        public var scaleMatrix: matrix_float4x4 = .init(1)
        public var rotateMatrix: matrix_float4x4 = .init(1)
        public var positionMatrix: matrix_float4x4 = .init(1)
        public var lastMatrix: matrix_float4x4 = .init(1)
        public var voxelElementController: VoxelElementController.Model = .init()
        public var subnodes: [ObjectLink] = []
        public var staticCollisionElement: StaticCollisionElement.Model = .init()
        public var dynamicCollisionElement: DynamicCollisionElement.Model = .init()

        public init() { }

        public func load(object: Node, context: ILoadMangerContext) throws {
            object.isHidden = isHidden
            object.firstMatrix = firstMatrix
            object.scaleMatrix = scaleMatrix
            object.rotateMatrix = rotateMatrix
            object.positionMatrix = positionMatrix
            object.lastMatrix = lastMatrix
            voxelElementController.fill(object.voxelElementController)
            staticCollisionElement.fill(&object.staticCollisionElement)
            dynamicCollisionElement.fill(&object.dynamicCollisionElement)
            try subnodes.forEach { link in
                object.addSubnode(try context.load(link))
            }
        }

        public mutating func update(with object: Node) throws {
            isHidden = object.isHidden
            firstMatrix = object.firstMatrix
            scaleMatrix = object.scaleMatrix
            rotateMatrix = object.rotateMatrix
            positionMatrix = object.positionMatrix
            lastMatrix = object.lastMatrix
            voxelElementController.save(object.voxelElementController)
            staticCollisionElement.save(object.staticCollisionElement)
            dynamicCollisionElement.save(object.dynamicCollisionElement)
            subnodes = []
            for node in object.subnodes {
                subnodes.append(.init(node))
            }
        }

        public func saveSubobjects(_ object: Node, context: ISaveMangerContext) throws {
            for node in object.subnodes {
                let link = ObjectLink(object)
                if subnodes.contains(link) {
                    try context.save(link, object: node)
                }
            }
        }
    }
}
