import simd
import GameSwiftEngine

protocol IPlayerActiveble: Node {
    func action(_ player: PlayerNode)
}

class PlayerNode: Node {
    var moveSpeed: GEFloat = 2
    var rotateSpeed: GEFloat = GEFloat.pi / 4

    let camera: CameraNode

    private let container = Node()

    private lazy var gravitationController = GravitationController(node: self)

    private lazy var moveControllerAnimation = PlayerMoveControllerAnimation(container: self.container)
    private var moveAnimation: NodeAnimationController?
    private var isMove: Bool = false

    init(camera: CameraNode = CameraNode()) {
        self.camera = camera
        super.init()

        addSubnode(container)
        container.addSubnode(camera)

        dynamicCollisionElement.isActive = true
        dynamicCollisionElement.radius = 0.5

        let light = LightNode()
        light.angle = .pi / 8
        light.attenuationAngle = .pi / 16
        light.power = 3
        light.color = .one
        light.move(to: .init(0.05, -0.3, 0))
        light.isShadow = true
        light.shadowSkipFrame = 1
        camera.addSubnode(light)
    }

    override func loop(_ time: Double, size: Size) throws {
        try? super.loop(time, size: size)
        gravitationController.update(with: GEFloat(time))
        updateMoveAnimation()
    }

    func updateMoveAnimation() {
        moveControllerAnimation.isMove = isMove
        isMove = false
    }

    func action() {
        (getNodesWithDirection().first(where: { $0 is IPlayerActiveble }) as? IPlayerActiveble)?.action(self)
    }

    func movePlayer(_ value: vector_float2) {
        isMove = true
        moveControllerAnimation.speed = length(value)
        let x: vector_float4 = .init(x: 1, y: 0, z: 0, w: 1)
        let y: vector_float4 = .init(x: 0, y: 0, z: 1, w: 1)
        let dx = simd_mul(rotateMatrix, x)
        let dy = simd_mul(rotateMatrix, y)
        var value = value
        value.x *= moveSpeed
        value.y *= moveSpeed
        move(on: .init(x: dx.x * value.x, y: dx.y * value.x, z: dx.z * value.x))
        move(on: .init(x: dy.x * value.y, y: dy.y * value.y, z: dy.z * value.y))
        positionMatrix[3][1] = 0
    }

    func rotatePlayer(_ value: vector_float2) {
        let x: vector_float4 = .init(x: 0, y: 1, z: 0, w: 1)
        let y: vector_float4 = .init(x: 1, y: 0, z: 0, w: 1)
        let dx = x
        let dy = simd_mul(rotateMatrix, y)
        var value = value
        value.x *= -rotateSpeed
        value.y *= -rotateSpeed
        rotate(on: value.x, axis: .init(x: dx.x, y: dx.y, z: dx.z))
        rotate(on: value.y, axis: .init(x: dy.x, y: dy.y, z: dy.z))
    }
}
