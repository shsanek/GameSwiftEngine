import simd

public final class Sprite3DNode: Node {
    public var texture: Texture? {
        didSet {
            encoder.texture = texture
        }
    }
    private let encoder: Sprite3DInput

    public init(texture: Texture?, size: Size) {
        let x = size.width / 2
        let y = size.height / 2
        let encoder = Sprite3DInput(
            texture: texture,
            vertexs: [
                .init(position: .init(x: -x, y: -y, z: 0), uv: .init(0, 1)),
                .init(position: .init(x: -x, y: y, z: 0), uv: .init(0, 0)),
                .init(position: .init(x: x, y: y, z: 0), uv: .init(1, 0)),

                .init(position: .init(x: -x, y: -y, z: 0), uv: .init(0, 1)),
                .init(position: .init(x: x, y: -y, z: 0), uv: .init(1, 1)),
                .init(position: .init(x: x, y: y, z: 0), uv: .init(1, 0))
            ]
        )
        self.encoder = encoder
        self.texture = texture
        super.init()
        addRenderInputs(encoder)
    }

    public init(
        vertexs: [Sprite3DInput.VertexInput],
        texture: Texture?
    ) {
        let encoder = Sprite3DInput(
            texture: texture,
            vertexs: vertexs
        )
        self.encoder = encoder
        self.texture = texture
        super.init()
        addRenderInputs(encoder)
    }
}
