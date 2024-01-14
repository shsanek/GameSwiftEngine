public final class GrassNode: Node, ITexturable {
    public var texture: ITexture? {
        didSet {
            input.texture = texture
        }
    }

    public var lowSectionsCount: Int = 1 {
        didSet {
            update()
        }
    }
    public var heightSectionsCount: Int = 2 {
        didSet {
            update()
        }
    }

    public var width: GEFloat = 1.0 {
        didSet {
            update()
        }
    }
    public var height: GEFloat = 1.0 {
        didSet {
            update()
        }
    }

    public var lowModelsCount: Int = 10 {
        didSet {
            update()
        }
    }
    public var heightModelsCount: Int = 30 {
        didSet {
            update()
        }
    }

    private let input = GrassInput(texture: nil, lowVertexs: [], heightVertexs: [])

    public override init() {
        super.init()
        self.addRenderInput(input)
        self.update()
    }

    public override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        self.input.time += Float32(time)
    }

    private static func generate(section: Int, height: Float, width: Float) -> [GrassVertex] {
        guard section != 0 else {
            return [.init(position: .zero, uv: .zero), .init(position: .zero, uv: .zero), .init(position: .zero, uv: .zero)]
        }
        let shiftHeight = (height / Float(section))
        let shiftWidth = (width / Float(section))
        var result: [GrassVertex] = []
        for index in 0..<(section - 1) {
            let bottom = Float(index) * shiftHeight
            let top = Float(index + 1) * shiftHeight
            let bottomWidth = Float(section - index - 1) * shiftWidth
            let topWidth = Float(section - index) * shiftWidth
            result.append(contentsOf: [
                .init(position: .init(x: -topWidth / 2, y: bottom, z: 0), uv: .zero),
                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: .zero),
                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: .zero),

                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: .zero),
                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: .zero),
                .init(position: .init(x: -topWidth / 2, y: bottom, z: 0), uv: .zero),

                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: .zero),
                .init(position: .init(x: bottomWidth / 2, y: top, z: 0), uv: .zero),
                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: .zero),

                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: .zero),
                .init(position: .init(x: bottomWidth / 2, y: top, z: 0), uv: .zero),
                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: .zero),
            ])
        }
        let bottom = Float(section - 1) * shiftHeight
        let top = Float(section) * shiftHeight
        let bottomWidth = shiftWidth
        result.append(contentsOf: [
            .init(position: .init(x: -bottomWidth / 2, y: bottom, z: 0), uv: .zero),
            .init(position: .init(x: bottomWidth / 2, y: bottom, z: 0), uv: .zero),
            .init(position: .init(x: 0, y: top, z: 0), uv: .zero),

            .init(position: .init(x: 0, y: top, z: 0), uv: .zero),
            .init(position: .init(x: bottomWidth / 2, y: bottom, z: 0), uv: .zero),
            .init(position: .init(x: -bottomWidth / 2, y: bottom, z: 0), uv: .zero),
        ])
        return result
    }

    private func update() {
        input.hightCount = heightModelsCount
        input.lowCount = lowModelsCount
        input.heightVertexs = Self.generate(section: heightSectionsCount, height: height, width: width)
        input.lowVertexs = Self.generate(section: lowSectionsCount, height: height, width: width)
    }
}

import ObjectEditor
import SwiftUI

@EditorModification<GrassNode>
struct GrassNodeModification: IEditorModification {
    @Editable var lowSectionsCount: Int = 1
    @Editable var heightSectionsCount: Int = 2

    @Editable var width: GEFloat = 1.0
    @Editable var height: GEFloat = 1.0

    @Editable var lowModelsCount: Int = 10
    @Editable var heightModelsCount: Int = 30
}



