import simd

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
    public var hightSectionsCount: Int = 2 {
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
    public var hightModelsCount: Int = 30 {
        didSet {
            update()
        }
    }

    public var density: GEFloat = 1.0 {
        didSet {
            update()
        }
    }

    public var windForce: GEFloat? = 1.0 {
        didSet {
            update()
        }
    }

    public var windNoiseScale: GEFloat? = 1.0 {
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
        var result: [GrassVertex] = []
        let uv: vector_float2 = .init(x: 6.5 / 16, y: 2.5 / 16)
        for index in 0..<(section - 1) {
            let bottom = Float(index) * shiftHeight
            let top = Float(index + 1) * shiftHeight
            let bottomWidth = width
            let topWidth = width
            result.append(contentsOf: [
                .init(position: .init(x: -topWidth / 2, y: bottom, z: 0), uv: uv),
                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: uv),
                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: uv),

                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: uv),
                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: uv),
                .init(position: .init(x: -topWidth / 2, y: bottom, z: 0), uv: uv),

                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: uv),
                .init(position: .init(x: bottomWidth / 2, y: top, z: 0), uv: uv),
                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: uv),

                .init(position: .init(x: topWidth / 2, y: bottom, z: 0), uv: uv),
                .init(position: .init(x: bottomWidth / 2, y: top, z: 0), uv: uv),
                .init(position: .init(x: -bottomWidth / 2, y: top, z: 0), uv: uv),
            ])
        }
        let bottom = Float(section - 1) * shiftHeight
        let top = Float(section) * shiftHeight
        let bottomWidth = width
        result.append(contentsOf: [
            .init(position: .init(x: -bottomWidth / 2, y: bottom, z: 0), uv: uv),
            .init(position: .init(x: bottomWidth / 2, y: bottom, z: 0), uv: uv),
            .init(position: .init(x: 0, y: top, z: 0), uv: .zero),

                .init(position: .init(x: 0, y: top, z: 0), uv: .zero),
            .init(position: .init(x: bottomWidth / 2, y: bottom, z: 0), uv: uv),
            .init(position: .init(x: -bottomWidth / 2, y: bottom, z: 0), uv: uv),
        ])
        return result
    }

    private func update() {
        input.windForce = max(min(windForce ?? 1.0, 1.0), 0.0)
        input.windNoiseScale = windNoiseScale ?? 1.0
        input.density = density
        input.hightCount = hightModelsCount
        input.lowCount = lowModelsCount
        input.heightVertexs = Self.generate(section: hightSectionsCount, height: height, width: width)
        input.lowVertexs = Self.generate(section: lowSectionsCount, height: height, width: width)
    }
}

import ObjectEditor
import SwiftUI

@EditorModification<GrassNode>
struct GrassNodeModification: IEditorModification {
    @Editable var lowSectionsCount: Int = 1
    @Editable var hightSectionsCount: Int = 2

    @Editable var width: GEFloat = 1.0
    @Editable var height: GEFloat = 1.0

    @Editable var lowModelsCount: Int = 10
    @Editable var hightModelsCount: Int = 30

    @Editable var density: GEFloat = 1.0

    @Editable var windForce: GEFloat? = 1.0
    @Editable var windNoiseScale: GEFloat? = 1.0
}



