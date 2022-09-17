import simd

open class Node {
    public var parent: Node? {
        storageParent
    }

    public var sceene: SceeneNode? {
        storageSceene
    }

    private weak var storageParent: Node?
    private weak var storageSceene: SceeneNode? {
        didSet {
            if storageSceene === oldValue || sceene !== storageSceene {
                return
            }
            subnodes.forEach { $0.storageSceene = sceene }
            didMoveSceene(oldSceene: oldValue, sceene: sceene)
        }
    }

    private(set) var renderInputs: [AnyInputRenderEncodable] = []
    private(set) var subnodes: [Node] = []
    private var animations: [NodeAnimationController] = []

    open var isHidden: Bool = false

    public var firstMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if firstMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }
    public var scaleMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if scaleMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }
    public var rotateMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if rotateMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }
    public var positionMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if positionMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }
    public var lastMatrix: matrix_float4x4 = .init(1) {
        didSet {
            if lastMatrix == oldValue {
                return
            }
            storageModelMatrix = nil
        }
    }
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

    var absoluteTransformStorage: matrix_float4x4? {
        didSet {
            if absoluteTransformStorage == oldValue {
                return
            }
            if absoluteTransformStorage == nil {
                isNeedUpdateStaticCollisionMapCordinate = true
                isNeedUpdateActivablePosition = true
                subnodes.forEach { $0.absoluteTransformStorage = nil }
            }
        }
    }

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

    private lazy var staticCollisionProvider: StaticCollisionProvider = StaticCollisionProvider(node: self)
    private lazy var dynamicCollisionProvider: DynamicCollisionProvider = DynamicCollisionProvider(node: self)

    public var dynamicCollisionRadius: Float? = nil {
        didSet {
            dynamicCollisionUpdate()
        }
    }

    public var staticCollisionPlanes: [StaticCollisionPlane] = [] {
        didSet {
            staticCollisionProvider.planes = staticCollisionPlanes
            updateStaticCollisionProvider()
        }
    }

    public var staticCollisionMapCordinate: [vector_float2] = [.init(x: 0, y: 0)] {
        didSet {
            guard staticCollisionProvider.isActive else {
                return
            }
            sceene?.collisionController.removeProvider(staticCollisionProvider)
            staticCollisionMapCordinateUpdate()
            isNeedUpdateStaticCollisionMapCordinate = false
        }
    }

    private var isNeedUpdateStaticCollisionMapCordinate: Bool = false
    private var isNeedUpdateActivablePosition: Bool = false

    public init() {
    }

    public func updateActivablePositionIfNeeded() {
        if isNeedUpdateActivablePosition, let node = self as? INodeActivable {
            sceene?.activableController.removeActivable(node)
            sceene?.activableController.addActivable(
                in: .init(
                    x: Int(position.x),
                    y: Int(position.z)
                ),
                node
            )
        }
    }

    func updateStaticCollisionMapCordinateIfNeeded() {
        guard staticCollisionProvider.isActive && isNeedUpdateStaticCollisionMapCordinate else {
            return
        }
        sceene?.collisionController.removeProvider(staticCollisionProvider)
        staticCollisionMapCordinateUpdate()
        isNeedUpdateStaticCollisionMapCordinate = false
    }

    private func updateStaticCollisionProvider() {
        if staticCollisionPlanes.isEmpty && staticCollisionProvider.isActive {
            sceene?.collisionController.removeProvider(staticCollisionProvider)
        }
        if !staticCollisionPlanes.isEmpty && !staticCollisionProvider.isActive {
            staticCollisionMapCordinateUpdate()
        }
        isNeedUpdateStaticCollisionMapCordinate = false
    }

    private func staticCollisionMapCordinateUpdate() {
        for MapCordinate in staticCollisionMapCordinate {
            let cord = matrix_multiply(absoluteTransform, .init(MapCordinate.x, 0, MapCordinate.y, 1))
            sceene?.collisionController.addProvider(
                staticCollisionProvider,
                in: .init(x: Int(cord.x), y: Int(cord.z))
            )
        }
        if staticCollisionMapCordinate.isEmpty {
            sceene?.collisionController.addProvider(
                staticCollisionProvider
            )
        }
    }

    private func dynamicCollisionUpdate() {
        if !dynamicCollisionProvider.isActive && dynamicCollisionRadius != nil {
            sceene?.collisionController.addProvider(dynamicCollisionProvider)
        }
        if dynamicCollisionProvider.isActive && dynamicCollisionRadius == nil {
            sceene?.collisionController.removeProvider(dynamicCollisionProvider)
        }
    }

    private var storageModelMatrix: matrix_float4x4? {
        didSet {
            if storageModelMatrix == nil {
                absoluteTransformStorage = nil
            }
        }
    }

    open func loop(_ time: Double, size: Size) throws {
        let animations = self.animations
        animations.forEach { $0.loop(Float(time)) }
    }

    open func didMoveSceene(oldSceene: SceeneNode?, sceene: SceeneNode?) {
        if staticCollisionProvider.isActive {
            oldSceene?.collisionController.removeProvider(staticCollisionProvider)
        }
        staticCollisionMapCordinateUpdate()
        if dynamicCollisionProvider.isActive {
            oldSceene?.collisionController.removeProvider(dynamicCollisionProvider)
        }
        dynamicCollisionUpdate()
        if let node = self as? INodeActivable {
            oldSceene?.activableController.removeActivable(node)
            isNeedUpdateActivablePosition = true
            updateActivablePositionIfNeeded()
        }
    }

    public func getParent<T>(with type: T.Type) -> T? {
        var node = parent
        while let current = node {
            if let result = current as? T {
                return result
            }
            node = current.parent
        }
        return nil
    }
}

extension Node {
    public var position: vector_float3 {
        let position = matrix_multiply(absoluteTransform, .init(0, 0, 0, 1))
        return .init(x: position.x, y: position.y, z: position.z)
    }

    public var localPosition: vector_float3 {
        .init(
            x: positionMatrix[3][0],
            y: positionMatrix[3][1],
            z: positionMatrix[3][2]
        )
    }

    public func moveGlobal(to position: vector_float3) {
        move(to: .zero)
        let position = matrix_multiply(absoluteTransform.inverse, vector_float4(position, 1))
        move(to: .init(x: position.x, y: position.y, z: position.z))
    }

    public func move(to position: vector_float3) {
        positionMatrix = translationMatrix4x4(position.x, position.y, position.z)
    }

    public func move(on position: vector_float3) {
        let position = translationMatrix4x4(position.x, position.y, position.z)
        positionMatrix = matrix_multiply(position, positionMatrix)
    }
}

extension Node {
    public func rotate(to angle: Float, axis: vector_float3) {
        rotateMatrix = rotationMatrix4x4(radians: angle, axis: axis)
    }

    public func rotate(on angle: Float, axis: vector_float3) {
        let rotation = rotationMatrix4x4(radians: angle, axis: axis)
        rotateMatrix = matrix_multiply(rotation, rotateMatrix)
    }
}

extension Node {
    public var scale: vector_float3 {
        .init(
            x: scaleMatrix[0][0],
            y: scaleMatrix[1][1],
            z: scaleMatrix[2][2]
        )
    }

    public func scale(to scale: vector_float3) {
        let scale = matrix_float4x4(
            .init(x: scale.x, y: 0, z: 0, w: 0),
            .init(x: 0, y: scale.y, z: 0, w: 0),
            .init(x: 0, y: 0, z: scale.z, w: 0),
            .init(x: 0, y: 0, z: 0, w: 1)
        )
        scaleMatrix = scale
    }

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
    public func addRenderInputs(_ encodable: AnyInputRenderEncodable) {
        renderInputs.append(encodable)
    }

    public func removeRenderInputs(_ encodable: AnyInputRenderEncodable) {
        renderInputs.removeAll(where: { $0 === encodable })
    }
}

extension Node {
    public func lockUpdateCordinate(_ handler: () -> Void) {
        let isNeedUpdateActivablePosition = self.isNeedUpdateActivablePosition
        let isNeedUpdateStaticCollisionMapCordinate = self.isNeedUpdateStaticCollisionMapCordinate
        handler()
        self.isNeedUpdateActivablePosition = isNeedUpdateActivablePosition
        self.isNeedUpdateStaticCollisionMapCordinate = isNeedUpdateStaticCollisionMapCordinate
    }
}

extension Node {
    public func addSubnode(_ node: Node) {
        node.absoluteTransformStorage = nil
        node.storageParent?.removeSubnode(node)
        subnodes.append(node)
        node.storageParent = self
        node.storageSceene = sceene
    }

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
        with functions: inout [String: AnyObject],
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
                    with: &functions,
                    renderInput: renderInput
                )
            }
            var renderInput = renderInput
            renderInput.projectionMatrix = cameraMatrix
            renderInput.currentPosition = modelMatrix
            for input in node.renderInputs {
                try input.run(with: &functions, input: renderInput)
            }
        }
    }
}

extension Node {
    public func activables(_ angle: Float = .pi / 2) ->  [INodeActivable] {
        let z = vector_float4(0, 0, 1, 1)
        let direction = matrix_multiply(absoluteTransform, z) - vector_float4(position, 1)
        return sceene?.activableController.getActivableNode(
            in: position,
            lng: 1.5,
            direction: .init(x: direction.x, y: direction.y, z: direction.z),
            angle: angle
        ) ?? []
    }
}

extension Node {
    @discardableResult
    public func addAnimation(
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
