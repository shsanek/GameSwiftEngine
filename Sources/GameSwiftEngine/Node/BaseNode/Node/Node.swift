import simd
import ObjectEditor

/// Base building block for you app
open class Node {
    public var omIdentifier: String?
    public var omModifications: [IAnyOMModification] = []
    public var omIgnore: Bool = false

    /// Parent - current parent node or nil if not contained in hierarchy
    public var parent: Node? {
        storageParent
    }

    /// Current - current SceneNode or nil if hierarchy is not attached to the SceneNode
    public var scene: SceneNode? {
        storageSceene
    }

    /// Responsible for display, if true then ingore all renderInputs
    open var isHidden: Bool = false {
        didSet {
            objectControllers.forEach { $0.isHidden = true }
        }
    }

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
    /// `absoluteTransform = parent.absoluteTransform * modelMatrix`
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
                scene?.updatePool.add(self)
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

    private(set) var objectControllers: [Object3DController] = []
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

        objectControllers.forEach { try? oldSceene?.objects3DArraysManager.removeController($0) }
        objectControllers.forEach { try? scene?.objects3DArraysManager.addController($0) }

        if !renderInputs.isEmpty {
            oldSceene?.renderPool.remove(self)
            scene?.renderPool.add(self)
        }
    }
}

extension Node {
    func updateObjectControllers() {
        objectControllers.forEach {
            $0.modelMatrix = absoluteTransform
        }
    }

    public func addObjectController(_ controller: Object3DController) {
        objectControllers.append(controller)
        try? scene?.objects3DArraysManager.addController(controller)
    }

    public func removeObjectController(_ controller: Object3DController) {
        objectControllers.removeAll(where: { controller === $0 })
        try? scene?.objects3DArraysManager.removeController(controller)
    }
}

extension Node {
    /// Global position in hierarchy
    ///  `position = absoluteTransform * .zero`
    public var position: vector_float3 {
        get {
            let position = matrix_multiply(absoluteTransform, .init(0, 0, 0, 1))
            return .init(x: position.x, y: position.y, z: position.z)
        }
        set {
            let transform = (parent?.absoluteTransform ?? .init(1)).inverse * newValue.to4
            move(to: transform.xyz)
        }
    }

    /// Global position in node
    ///  `position = absoluteTransform * .zero`
    public var localPosition: vector_float3 {
        get {
            .init(
                x: positionMatrix[3][0],
                y: positionMatrix[3][1],
                z: positionMatrix[3][2]
            )
        }
        set {
            move(to: newValue)
        }
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
    public var localRotate: vector_float3 {
        get {
            .zero
        }
        set {
            rotateMatrix = rotationMatrix4x4(radians: 0, axis: .one)
            rotate(on: newValue.x, axis: .init(x: 1, y: 0, z: 0))
            rotate(on: newValue.y, axis: .init(x: 0, y: 1, z: 0))
            rotate(on: newValue.z, axis: .init(x: 0, y: 0, z: 1))
        }
    }

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
    /// Scale
    public var scale: vector_float3 {
        get {
            let x = (absoluteTransform * vector_float4(x: 1, y: 0, z: 0, w: 1)) - position.to4
            let y = (absoluteTransform * vector_float4(x: 0, y: 1, z: 0, w: 1)) - position.to4
            let z = (absoluteTransform * vector_float4(x: 0, y: 0, z: 1, w: 1)) - position.to4

            return vector_float3(length(x), length(y), length(z))
        }
    }

    /// Local scale
    public var localScale: vector_float3 {
        get {
            .init(
                x: scaleMatrix[0][0],
                y: scaleMatrix[1][1],
                z: scaleMatrix[2][2]
            )
        }
        set {
            scale(to: newValue)
        }
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
        if renderInputs.isEmpty {
            scene?.renderPool.add(self)
        }
        renderInputs.append(encodable)
    }

    /// Remove render input for display
    /// See more `AnyRenderHandler`, `LoopController`
    /// - Parameter encodable: old encodable
    public func removeRenderInputs(_ encodable: AnyRenderHandler) {
        renderInputs.removeAll(where: { $0 === encodable })
        if renderInputs.isEmpty {
            scene?.renderPool.remove(self)
        }
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
    static func metalRender(
        camera: CameraNode,
        node: Node,
        renderInput: MetalRenderInput
    ) throws {
        if node.isHidden == false {
            var renderInput = renderInput
            renderInput.currentPosition = node.absoluteTransform
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

extension Node: IOMNode {
    
    public var omSubnodes: [IOMNode] {
        subnodes.map { $0 as IOMNode }
    }

    public func omAddSubnode(_ node: IOMNode) throws {
        guard let obj = node as? Node else {
            throw EditorError.message("`\(type(of: node))` is not `Node`")
        }
        addSubnode(obj)
    }

    public func omRemoveFromSupernode() throws {
        removeFromParent()
    }
}
