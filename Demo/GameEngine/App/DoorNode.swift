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
        let x: GEFloat = 0.5
        let y: GEFloat = 0.5
        let z: GEFloat = 0.1
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
        addRenderInput(encoder)

        addCollision(y: z, angle: 0)
        addCollision(y: -z, angle: -.pi)

        let light = LightNode()
        light.power = 0.05
        light.color = .init(x: 1, y: 0, z: 0)
        //addSubnode(light)
        light.move(to: .init(0, 0.5, 0))
    }

    

    override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        voxelElementController.lockNeedUpdate {
            let speed: Double = 1
            if localPosition.x < 1 && state == .open {
                move(on: .init(x: GEFloat(speed * time), y: 0, z: 0))
            }
            if state == .open && localPosition.x > 1 {
                move(to: .init(x: 1, y: 0, z: 0))
            }
            if localPosition.x > 0 && state == .close {
                move(on: .init(x: -GEFloat(speed * time), y: 0, z: 0))
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
