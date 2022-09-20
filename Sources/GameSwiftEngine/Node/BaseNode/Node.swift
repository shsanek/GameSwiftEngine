import simd

/// Base building block for you app
open class Node {
    /// Parent - current parent node or nil if not contained in hierarchy
    public var parent: Node? {
        storageParent
    }

    /// Current - current SceneNode or nil if hierarchy is not attached to the SceneNode
    public var scene: SceneNode? {
        storageSceene
    }

    /// Responsible for display, if true then ingore all renderInputs
    open var isHidden: Bool = false

    /// First matrix for transform
    /// * see also absoluteTransform, modelMatrix
    public var firstMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if firstMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }

    /// Scale matrix for transform
    /// * see also `absoluteTransform`, `modelMatrix`
    public var scaleMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if scaleMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }

    /// Rotate matrix for transform
    /// * see also `absoluteTransform`, `modelMatrix`
    public var rotateMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if rotateMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }

    /// Position matrix for transform
    /// * see also `absoluteTransform`, `modelMatrix`
    public var positionMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if positionMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }

    /// Last matrix for transform
    /// * see also `absoluteTransform`, `modelMatrix`
    public var lastMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if lastMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }


    /// Result local transform matrix for node
    /// `modelMatrix = lastMatrix * positionMatrix * rotateMatrix * scaleMatrix * firstMatrix`
    public var modelMatrix: matrix_float4x4 {
        if let storageModelMatrix = storageModelMatrix {
            return storageModelMatrix
        }
        var matrix = firstMatrix
        matrix = matrix_multiply(scaleMatrix, matrix)
        matrix = matrix_multiply(rotateMatrix, matrix)
        matrix = matrix_multiply(positionMatrix, matrix)
        matrix = matrix_multiply(lastMatrix, matrix)
        storageModelMatrix = matrix
        return matrix
    }

    /// Result transform taking into account the transformations of the parents
    /// `modelMatrix = lastMatrix * positionMatrix * rotateMatrix * scaleMatrix * firstMatrix`
    public var absoluteTransform: matrix_float4x4 {
        if let absoluteTransformStorage = absoluteTransformStorage {
            return absoluteTransformStorage
        }
        let matrix: matrix_float4x4
        if let parent = self.parent {
            matrix = matrix_multiply(parent.absoluteTransform, self.modelMatrix)
        } else {
            matrix = self.modelMatrix
        }
        absoluteTransformStorage = matrix
        return matrix
    }

    /// VoxelController - empty by default
    /// add element in groups ot points for active
    public private(set) lazy var voxelElementController = VoxelElementController(node: self)

    /// Controller for static collision
    /// Static collision not affect position current node, but can affect other nodes
    /// See more in `CollisionController`
    public var staticCollisionElement = StaticCollisionElement()

    /// Informat for dynamic collision
    /// Dynamic collsion can affect position current node
    /// See more in `CollisionController`
    public lazy var dynamicCollisionElement: DynamicCollisionElement = {
        DynamicCollisionElement(voxelElementController: voxelElementController)
    }()


    private var absoluteTransformStorage: matrix_float4x4? {
        didSet {
            if absoluteTransformStorage == oldValue {
                return
            }
            if absoluteTransformStorage == nil {
                voxelElementController.setNeedPointsUpdate()
                subnodes.forEach { $0.absoluteTransformStorage = nil }
            }
        }
    }

    private weak var storageParent: Node?
    private weak var storageSceene: SceneNode? {
        didSet {
            if storageSceene === oldValue || scene !== storageSceene {
                return
            }
            subnodes.forEach { $0.storageSceene = scene }
            didMoveSceene(oldSceene: oldValue, scene: scene)
        }
    }

    private(set) var renderInputs: [AnyRenderHandler] = []
    private(set) var subnodes: [Node] = []
    private var animations: [NodeAnimationController] = []

    private var storageModelMatrix: matrix_float4x4? {
        didSet {
            if storageModelMatrix == nil {
                absoluteTransformStorage = nil
            }
        }
    }

    /// Init
    public init() {
    }

    /// Main control methos
    /// Called before all drawings. One once per app cycle.
    /// See more in `LoopController`
    /// - Parameters:
    ///   - time: delta between frames
    ///   - size: current screen resalution size
    open func loop(_ time: Double, size: Size) throws {
        let animations = self.animations
        animations.forEach { $0.loop(GEFloat(time)) }
    }

    /// called on change scene (rootNode)
    /// - Parameters:
    ///   - oldSceene: if the node was already on the scene
    ///   - scene: new scene
    open func didMoveSceene(oldSceene: SceneNode?, scene: SceneNode?) {
        oldSceene?.voxelsSystemController.removeController(voxelElementController)
        scene?.voxelsSystemController.addController(voxelElementController)
    }
}

extension Node {
    /// Global position in hierarchy
    ///  `position = absoluteTransform * .zero`
    public var position: vector_float3 {
        let position = matrix_multiply(absoluteTransform, .init(0, 0, 0, 1))
        return .init(x: position.x, y: position.y, z: position.z)
    }

    /// Global position in node
    ///  `position = absoluteTransform * .zero`
    public var localPosition: vector_float3 {
        .init(
            x: positionMatrix[3][0],
            y: positionMatrix[3][1],
            z: positionMatrix[3][2]
        )
    }

    /// Change local position
    /// Fully replace positionMatrix
    /// - Parameter position: new position
    public func move(to position: vector_float3) {
        positionMatrix = translationMatrix4x4(position.x, position.y, position.z)
    }

    /// Change local position
    /// - Parameter position: offset
    public func move(on position: vector_float3) {
        let position = translationMatrix4x4(position.x, position.y, position.z)
        positionMatrix = matrix_multiply(position, positionMatrix)
    }
}

extension Node {
    /// Change local rotate
    /// Fully replace rotateMatrix
    /// - Parameters:
    ///   - angle: angle
    ///   - axis: normalized axis
    public func rotate(to angle: GEFloat, axis: vector_float3) {
        rotateMatrix = rotationMatrix4x4(radians: angle, axis: axis)
    }

    /// Change local rotate
    /// `rotate = newRotate * rotateMatrix`
    /// - Parameters:
    ///   - angle: angle
    ///   - axis: normalized axis
    public func rotate(on angle: GEFloat, axis: vector_float3) {
        let rotation = rotationMatrix4x4(radians: angle, axis: axis)
        rotateMatrix = matrix_multiply(rotation, rotateMatrix)
    }
}

extension Node {
    /// Local scale
    public var scale: vector_float3 {
        .init(
            x: scaleMatrix[0][0],
            y: scaleMatrix[1][1],
            z: scaleMatrix[2][2]
        )
    }

    /// Change scale
    /// - Parameter scale: newScale
    public func scale(to scale: vector_float3) {
        let scale = matrix_float4x4(
            .init(x: scale.x, y: 0, z: 0, w: 0),
            .init(x: 0, y: scale.y, z: 0, w: 0),
            .init(x: 0, y: 0, z: scale.z, w: 0),
            .init(x: 0, y: 0, z: 0, w: 1)
        )
        scaleMatrix = scale
    }

    /// Change scale
    /// - Parameter scale: add scale
    public func scale(on scale: vector_float3) {
        let scale = matrix_float4x4(
            .init(x: scale.x, y: 0, z: 0, w: 0),
            .init(x: 0, y: scale.y, z: 0, w: 0),
            .init(x: 0, y: 0, z: scale.z, w: 0),
            .init(x: 0, y: 0, z: 0, w: 1)
        )
        scaleMatrix = matrix_multiply(scale, scaleMatrix)
    }
}

extension Node {
    /// Add render input for display
    /// See more `AnyRenderHandler`, `LoopController`
    /// - Parameter encodable: new encodable
    public func addRenderInput(_ encodable: AnyRenderHandler) {
        renderInputs.append(encodable)
    }

    /// Remove render input for display
    /// See more `AnyRenderHandler`, `LoopController`
    /// - Parameter encodable: old encodable
    public func removeRenderInputs(_ encodable: AnyRenderHandler) {
        renderInputs.removeAll(where: { $0 === encodable })
    }
}

extension Node {
    /// Add subnode in hierarchy
    /// - Parameter node: new node, node will be removed from the previous hierarchy
    public func addSubnode(_ node: Node) {
        node.absoluteTransformStorage = nil
        node.storageParent?.removeSubnode(node)
        subnodes.append(node)
        node.storageParent = self
        node.storageSceene = scene
    }

    /// Delete node from hierarchy
    public func removeFromParent() {
        absoluteTransformStorage = nil
        storageParent?.removeSubnode(self)
        storageSceene = nil
    }

    private func removeSubnode(_ node: Node) {
        node.storageParent = nil
        subnodes.removeAll(where: { $0 === node })
    }
}

extension Node {
    static func updateLoop(node: Node, time: Double, size: Size) throws {
        try node.loop(time, size: size)
        try node.subnodes.forEach { try updateLoop(node: $0, time: time, size: size) }
    }

    // METAL
    static func metalLoop(
        camera: CameraNode,
        node: Node,
        cameraMatrix: matrix_float4x4,
        modelMatrix: matrix_float4x4 = .init(1),
        renderInput: MetalRenderInput
    ) throws {
        if node.isHidden == false {
            let modelMatrix = matrix_multiply(modelMatrix, node.modelMatrix)
            for node in node.subnodes {
                try metalLoop(
                    camera: camera,
                    node: node,
                    cameraMatrix: cameraMatrix,
                    modelMatrix: modelMatrix,
                    renderInput: renderInput
                )
            }
            var renderInput = renderInput
            renderInput.projectionMatrix = cameraMatrix
            renderInput.currentPosition = modelMatrix
            for input in node.renderInputs {
                try input.run(input: renderInput)
            }
        }
    }
}

extension Node {
    /// Returns nodes from `voxelsSystemController`, in the current direction of the object
    /// `Direction = absoluteTransform *  (0, 0, 1, 1) - position`
    /// - Parameter angle: yaw angle
    /// - Returns: nodes sorted by distance
    public func getNodesWithDirection(_ angle: GEFloat = .pi / 2) ->  [Node] {
        let z = vector_float4(0, 0, 1, 1)
        let direction = matrix_multiply(absoluteTransform, z) - position.to4
        return scene?.voxelsSystemController.getActivableNodes(
            in: position,
            lng: 1.5,
            direction: .init(x: direction.x, y: direction.y, z: direction.z),
            angle: angle
        ) ?? []
    }
}

extension Node {
    /// Make and added Animation Controller
    /// - Parameters:
    ///   - animation: NodeAnimation
    ///   - shouldPlay: Bool default true, start animation immediately after adding
    ///   - completion: Completion with isFinish flag
    /// - Returns: AnimationController for controll animation
    @discardableResult public func addAnimation(
        _ animation: NodeAnimation,
        shouldPlay: Bool = true,
        completion: ((Bool) -> Void)? = nil
    ) -> NodeAnimationController {
        weak var weakController: NodeAnimationController?
        let controller = animation.makeController(for: self, completion: { [weak self] isFinish, _ in
            completion?(isFinish)
            self?.animations.removeAll(where: { $0 === weakController })
        })
        weakController = controller
        if shouldPlay {
            controller.play()
        }
        animations.append(controller)
        return controller
    }
}


public protocol TypeIdentifieble {
    var typeIdentifier: String { get }
}

public protocol LoadManger {
    func load<Type>(_ link: ObjectLink) throws -> Type
    func save(_ link: ObjectLink, object: TypeIdentifieble) throws
}

extension Node {
    public struct Model: Codable {
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

        public func fill(
            _ node: Node,
            manager: LoadManger
        ) throws {
            node.isHidden = isHidden
            node.firstMatrix = firstMatrix
            node.scaleMatrix = scaleMatrix
            node.rotateMatrix = rotateMatrix
            node.positionMatrix = positionMatrix
            node.lastMatrix = lastMatrix
            voxelElementController.fill(node.voxelElementController)
            staticCollisionElement.fill(&node.staticCollisionElement)
            dynamicCollisionElement.fill(&node.dynamicCollisionElement)
            try subnodes.forEach { link in
                node.addSubnode(try manager.load(link))
            }
        }

        public mutating func save(
            _ node: Node,
            manager: LoadManger
        ) {
        }
    }
}

