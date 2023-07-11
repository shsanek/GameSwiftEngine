import GameSwiftEngine

final class MainNode: SceneNode {
    var player: PlayerNode?

    override init() {
        super.init()
        addObject()
    }

    private func addObject() {
        let player = PlayerNode()
        scene?.mainCamera = player.camera
        self.player = player
        player.move(to: .init(x: -7, y: 0, z: -1))
        player.rotate(to: -.pi / 3 * 2, axis: .init(0, 1, 0))
        addSubnode(player)

        let light = LightNode()
        light.angle = .pi / 8
        light.attenuationAngle = .pi / 16
        light.power = 3
        light.color = .one
        light.move(to: .init(-7, -0.33333334, -10))
        light.rotate(to: -.pi, axis: .init(0, 1, 0))
        light.isShadow = true
        self.addSubnode(light)

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
weeeeeeezeeedlweew
wwwwwwwdwwwwwwwwww
weeeeeeeeeeeeeeeew
weeeeeeeeeeeeeeeew
weeeeeezeeemeeeeew
weeeeeeeeeeeeeeeew
wwwwwwwwwwwwwwwwww
"""
