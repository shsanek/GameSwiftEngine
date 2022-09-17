import simd
import GameSwiftEngine

class DoorNode: Node, INodeActive {
    enum State {
        case close
        case open
    }

    var state: State = .close

    private let texture: Texture?

    init(texture: Texture? = Texture.load(in: "1")) {
        self.texture = texture
        super.init()
        let x: Float = 0.5
        let y: Float = 0.5
        let z: Float = 0.1
        let encoder = Sprite3DInput(
            texture: texture,
            vertexs: [
                .init(position: .init(x: -x, y: -y, z: -z), uv: .init(0, 0)),
                .init(position: .init(x: -x, y: y, z: -z), uv: .init(0, 1)),
                .init(position: .init(x: x, y: y, z: -z), uv: .init(1, 1)),

                .init(position: .init(x: -x, y: -y, z: -z), uv: .init(0, 0)),
                .init(position: .init(x: x, y: -y, z: -z), uv: .init(1, 0)),
                .init(position: .init(x: x, y: y, z: -z), uv: .init(1, 1)),

                .init(position: .init(x: -x, y: -y, z: z), uv: .init(0, 0)),
                .init(position: .init(x: -x, y: y, z: z), uv: .init(0, 1)),
                .init(position: .init(x: x, y: y, z: z), uv: .init(1, 1)),

                .init(position: .init(x: -x, y: -y, z: z), uv: .init(0, 0)),
                .init(position: .init(x: x, y: -y, z: z), uv: .init(1, 0)),
                .init(position: .init(x: x, y: y, z: z), uv: .init(1, 1))
            ]
        )
        addRenderInputs(encoder)
//        let light = LightNode()
//        light.power = 0.5
//        light.color = .init(x: 1, y: 1, z: 1)
//        light.step = 1
//        light.angle = nil
//        light.move(to: .init(x: 0, y: -0.5, z: 0))
//        light.attenuationAngle = nil
//        addSubnode(light)

        addCollision(y: z, angle: 0)
        addCollision(y: -z, angle: -.pi)
    }

    

    override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        lockUpdateCordinate {
            let speed: Double = 1
            if localPosition.x < 1 && state == .open {
                move(on: .init(x: Float(speed * time), y: 0, z: 0))
            }
            if state == .open && localPosition.x > 1 {
                move(to: .init(x: 1, y: 0, z: 0))
            }
            if localPosition.x > 0 && state == .close {
                move(on: .init(x: -Float(speed * time), y: 0, z: 0))
            }
            if state == .close && localPosition.x < 0 {
                move(to: .init(x: 0, y: 0, z: 0))
            }
        }
    }

    func action() {
        state = (state == .close ? .open : .close)
    }
}
