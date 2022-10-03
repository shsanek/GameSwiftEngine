import simd

public enum Geometries {
    public static func plane(with size: Size) -> [VertexInput] {
        let x = size.width / 2
        let y = size.height / 2
        return [
            .init(position: .init(x: -x, y: -y, z: 0), uv: .init(0, 1)),
            .init(position: .init(x: -x, y: y, z: 0), uv: .init(0, 0)),
            .init(position: .init(x: x, y: y, z: 0), uv: .init(1, 0)),

            .init(position: .init(x: -x, y: -y, z: 0), uv: .init(0, 1)),
            .init(position: .init(x: x, y: -y, z: 0), uv: .init(1, 1)),
            .init(position: .init(x: x, y: y, z: 0), uv: .init(1, 0))
        ]
    }
}
