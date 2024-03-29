import GameSwiftEngine
import Foundation

class LiftNode: Node, INodeActive {
    enum State {
        case up
        case down
    }

    var state: State = .down

    private lazy var platform = addBottomRectNode(texture: .load(in: "Resources/Textures/STEEL_2B.png", bundle: Bundle.module))

    override init() {
        super.init()
        _ = platform
    }

    func action() {
        state = (state == .up) ? .down : .up
    }

    override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        voxelElementController.lockNeedUpdate {
            let speed: Double = 1
            if platform.localPosition.y < 1 && state == .up {
                platform.move(on: .init(x: 0, y: GEFloat(speed * time), z: 0))
            }
            if state == .up && platform.localPosition.y > 1 {
                platform.move(to: .init(x: 0, y: 1, z: 0))
            }
            if platform.localPosition.y > 0 && state == .down {
                platform.move(on: .init(x: 0, y: -GEFloat(speed * time), z: 0))
            }
            if state == .down && platform.localPosition.y < 0 {
                platform.move(to: .init(x: 0, y: 0, z: 0))
            }
        }
    }
}
