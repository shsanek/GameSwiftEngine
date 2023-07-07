public enum Sprite3DNodeGeometrySource: Codable {
    case empty
    case plane(_ size: Size)
    case vertexs(_ vertexs: [VertexInput])
}

extension Sprite3DNodeGeometrySource {
    public var onlyVertexs: [VertexInput]? {
        switch self {
        case .empty:
            return []
        case .plane(let size):
            return Geometries.plane(with: size)
        case .vertexs(let vertexs):
            return vertexs
        }
    }

    public var light: Self {
        switch self {
        case .vertexs:
            return .vertexs([])
        default:
            return self
        }
    }
}
