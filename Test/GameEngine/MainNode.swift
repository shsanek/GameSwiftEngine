import GameSwiftEngine

final class MainNode: SceeneNode {
    var player: PlayerNode?

    override init() {
        super.init()
        addObject()
    }

    private func addObject() {
        let player = PlayerNode(camera: mainCamera)
        self.player = player
        player.move(to: .init(x: -7, y: 0, z: -1))
        player.rotate(to: -.pi / 3 * 2, axis: .init(0, 1, 0))
        addSubnode(player)

        let light = LightNode()
        light.power = 10
        light.color = .init(x: 1, y: 1, z: 1)
        light.step = nil
        light.angle = .pi / 8
        light.attenuationAngle = .pi / 32

        let level = LevelNode(text: testMap)
        level.rotate(to: .pi, axis: .init(x: 0, y: 1, z: 0))
        addSubnode(level)
    }
}

//let testMap = """
//eeeeeeeeeeeeeeee
//eeeeeeeeeeeeeeee
//eeeeeeeeeeeeeeee
//eeeeeeweeeeeeeee
//eeeeeeeeeeeeeeee
//eeeeeeeeeeeeeeee
//eeeeeeeeeeeeeeee
//"""

let testMap =
"""
wwwwwwwwwwwwwwwwww
weeeeeeeeeeeeeeeew
weeeeeeeeeeeeeeeew
weeeeeeeeeeeeeeeew
weeeeeeeeeeewwweew
weeeeeeeeeeedlweew
wwwwwwwdwwwwwwwwww
weeeeeeeeeeeeeeeew
weeeeeeeeeeeeeeeew
weeeeeezeeeeeeeeew
weeeeeeeeeeeeeeeew
wwwwwwwwwwwwwwwwww
"""
