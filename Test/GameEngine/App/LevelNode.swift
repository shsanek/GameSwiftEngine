import simd
import GameSwiftEngine

class LevelNode: Node {
    enum RawMapTitle: String {
        case empty = "e"
        case door = "d"
        case wall = "w"
        case lift = "l"
        case zombee = "z"
        case mirror = "m"
    }

    enum MapTitle {
        case empty
        case door(_ node: DoorNode)
        case wall
        case lift(_ node: LiftNode)
    }

    private(set) var map: [[MapTitle]] = []
    let walls = Sprite3DInput(texture: Texture.load(in: "TECH_0F"), vertexs: [])
    let emptyBottoms = Sprite3DInput(texture: Texture.load(in: "RIVET_1A"), vertexs: [])
    let emptyTops = Sprite3DInput(texture: Texture.load(in: "CRATE_2L"), vertexs: [])


    let wallGeometry = ObjImporter.loadFile("wall_tech")

    init(text: String) {
        super.init()
        addRenderInput(walls)
        addRenderInput(emptyBottoms)
        addRenderInput(emptyTops)
        let result: [[RawMapTitle]] = text.split(separator: "\n").map {
            $0.map { RawMapTitle(rawValue: "\($0)") ?? .empty }
        }
        map = result.enumerated().map { row in
            row.element.enumerated().map { element in
                generateVertex(x: element.offset, y: row.offset, map: result)
            }
        }

        staticCollisionMapCordinate = []
        staticCollisionPlanes.append(
            .init(
                transform: translationMatrix4x4(0, -0.5, 0),
                size: .init(x: 1000, y: 1000)
            )
        )
    }

    private func generateVertex(x: Int, y: Int, map: [[RawMapTitle]]) -> MapTitle {
        switch map[y][x] {
        case .empty:
            return empty(for: x, y: y, map: map)
        case .door:
            return door(for: x, y: y, map: map)
        case .wall:
            return wall(for: x, y: y, map: map)
        case .lift:
            return lift(for: x, y: y, map: map)
        case .zombee:
            return zombee(for: x, y: y, map: map)
        case .mirror:
            return mirror(for: x, y: y, map: map)
        }
    }

    private func mirror(for x: Int, y: Int, map: [[RawMapTitle]]) -> MapTitle {
        let node = MirrorNode()
        node.move(to: .init(Float(x), 0, Float(y)))
        addSubnode(node)
        return empty(for: x, y: y, map: map)
    }

    private func zombee(for x: Int, y: Int, map: [[RawMapTitle]]) -> MapTitle {
        let node = ZombeeNode()
        node.move(to: .init(Float(x), 0, Float(y)))
        addSubnode(node)
        return empty(for: x, y: y, map: map)
    }

    private func empty(for x: Int, y: Int, map: [[RawMapTitle]]) -> MapTitle {
        emptyTops.vertexs.values.append(
            contentsOf: rect(
                .init(
                    a: .init(x: Float(x) - 0.5, y: 0.5, z: Float(y) - 0.5),
                    b: .init(x: Float(x) - 0.5, y: 0.5, z: Float(y) + 0.5),
                    c: .init(x: Float(x) + 0.5, y: 0.5, z: Float(y) + 0.5),
                    d: .init(x: Float(x) + 0.5, y: 0.5, z: Float(y) - 0.5)
                )
            )
        )
        emptyBottoms.vertexs.values.append(
            contentsOf: rect(
                .init(
                    a: .init(x: Float(x) - 0.5, y: -0.5, z: Float(y) - 0.5),
                    b: .init(x: Float(x) - 0.5, y: -0.5, z: Float(y) + 0.5),
                    c: .init(x: Float(x) + 0.5, y: -0.5, z: Float(y) + 0.5),
                    d: .init(x: Float(x) + 0.5, y: -0.5, z: Float(y) - 0.5)
                )
            )
        )

        return .empty
    }

    private func wall(for x: Int, y: Int, map: [[RawMapTitle]]) -> MapTitle {
        let rotate1 = rotationMatrix4x4(radians: .pi / 2.0, axis: .init(x: 1, y: 0, z: 0))
        var scale = matrix_float4x4(0.5)
        scale[3][3] = 1
        let baseTransform = matrix_multiply(rotate1, scale)
        func add(x: Float, y: Float, angle: Float) {
            let rotate2 = rotationMatrix4x4(radians: angle, axis: .init(x: 0, y: 1, z: 0))
            let transform = translationMatrix4x4(x, 0, y)
            var matrix = matrix_multiply(rotate2, baseTransform)
            matrix = matrix_multiply(transform, matrix)
            if let obj = self.wallGeometry?.geometryForInput(with: matrix) {
                walls.vertexs.values.append(contentsOf: obj)
            }
            let node = WallNode()
            node.staticCollisionMapCordinate.append(.init(x: x, y: y))
            node.staticCollisionPlanes.append(
                .init(
                    transform: matrix,
                    size: .init(x: 2, y: 2)
                )
            )
            addSubnode(node)
        }
        if x > 0 && map[y][x - 1] != .wall {
            add(x: Float(x) - 0.5, y: Float(y), angle: -.pi / 2.0)
        }
        if x + 1 < map[y].count && map[y][x + 1] != .wall {
            add(x: Float(x) + 0.5, y: Float(y), angle: .pi / 2.0)
        }
        if y - 1 > 0 && map[y - 1][x] != .wall {
            add(x: Float(x), y: Float(y) - 0.5, angle: -.pi)
        }
        if y + 1 < map.count && map[y + 1][x] != .wall {
            add(x: Float(x), y: Float(y) + 0.5, angle: 0)
        }
        return .wall
    }

    private func door(for x: Int, y: Int, map: [[RawMapTitle]]) -> MapTitle {
        let door = DoorNode()
        let node = ActiveContainer(node: door)
        if y > 0 && y + 1 < map.count && map[y-1][x] == .wall && map[y-1][x] == .wall {
            node.rotate(to: .pi / 2.0, axis: .init(x: 0, y: 1, z: 0))
        }
        node.move(to: .init(x: Float(x), y: 0, z: Float(y)))
        addSubnode(node)

        emptyBottoms.vertexs.values.append(
            contentsOf: rect(
                .init(
                    a: .init(x: Float(x) - 0.5, y: -0.5, z: Float(y) - 0.5),
                    b: .init(x: Float(x) - 0.5, y: -0.5, z: Float(y) + 0.5),
                    c: .init(x: Float(x) + 0.5, y: -0.5, z: Float(y) + 0.5),
                    d: .init(x: Float(x) + 0.5, y: -0.5, z: Float(y) - 0.5)
                )
            )
        )
        emptyTops.vertexs.values.append(
            contentsOf: rect(
                .init(
                    a: .init(x: Float(x) - 0.5, y: 0.5, z: Float(y) - 0.5),
                    b: .init(x: Float(x) - 0.5, y: 0.5, z: Float(y) + 0.5),
                    c: .init(x: Float(x) + 0.5, y: 0.5, z: Float(y) + 0.5),
                    d: .init(x: Float(x) + 0.5, y: 0.5, z: Float(y) - 0.5)
                )
            )
        )
        return .door(door)
    }

    private func lift(for x: Int, y: Int, map: [[RawMapTitle]]) -> MapTitle {
        let lift = LiftNode()
        let node = ActiveContainer(node: lift)
        node.move(to: .init(x: Float(x), y: 0, z: Float(y)))
        addSubnode(node)

        emptyBottoms.vertexs.values.append(
            contentsOf: rect(
                .init(
                    a: .init(x: Float(x) - 0.5, y: -0.51, z: Float(y) - 0.5),
                    b: .init(x: Float(x) - 0.5, y: -0.51, z: Float(y) + 0.5),
                    c: .init(x: Float(x) + 0.5, y: -0.51, z: Float(y) + 0.5),
                    d: .init(x: Float(x) + 0.5, y: -0.51, z: Float(y) - 0.5)
                )
            )
        )
        return .lift(lift)
    }
}

final class WallNode: Node {}

extension Node {
    func addCollision(x: Float = 0, y: Float = 0, angle: Float) {
        let rotate1 = rotationMatrix4x4(radians: .pi / 2.0, axis: .init(x: 1, y: 0, z: 0))
        let rotate2 = rotationMatrix4x4(radians: angle, axis: .init(x: 0, y: 1, z: 0))
        let transform = translationMatrix4x4(x, 0, y)
        var matrix = matrix_multiply(rotate2, rotate1)
        matrix = matrix_multiply(transform, matrix)
        self.staticCollisionPlanes.append(
            .init(
                transform: matrix,
                size: .init(x: 1, y: 1)
            )
        )
    }

    @discardableResult
    func addBottomRectNode(
        x: Float = 0,
        y: Float = 0,
        size: Size = .init(width: 1, height: 1),
        level: Float = 0,
        texture: Texture?,
        collision: Bool = true
    ) -> Sprite3DNode {
        let vertex = rect(
            .init(
                a: .init(x: Float(x) - size.width / 2, y: level - 0.5, z: Float(y) - size.height / 2),
                b: .init(x: Float(x) - size.width / 2, y: level - 0.5, z: Float(y) + size.height / 2),
                c: .init(x: Float(x) + size.width / 2, y: level - 0.5, z: Float(y) + size.height / 2),
                d: .init(x: Float(x) + size.width / 2, y: level - 0.5, z: Float(y) - size.height / 2)
            )
        )
        let node = Sprite3DNode(vertexs: vertex, texture: texture)
        addSubnode(node)
        if collision {
            let matrix = translationMatrix4x4(Float(x), level - 0.5, Float(y))
            node.staticCollisionPlanes.append(.init(transform: matrix, size: .init(x: size.width, y: size.height)))
        }
        return node
    }

    func rect(_ rect: Rect3D, uv: Rect2D = Rect2D()) -> [Sprite3DInput.VertexInput] {
        [
            .init(position: rect.a, uv: uv.a),
            .init(position: rect.b, uv: uv.b),
            .init(position: rect.c, uv: uv.c),
            .init(position: rect.c, uv: uv.c),
            .init(position: rect.d, uv: uv.d),
            .init(position: rect.a, uv: uv.a)
        ]
    }
}
