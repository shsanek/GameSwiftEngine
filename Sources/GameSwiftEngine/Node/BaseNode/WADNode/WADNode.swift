import WADFormat
#if canImport(SwiftUI)
import SwiftUI
#endif
import ObjectEditor
import simd

public final class WADNode: Node {
    var wadPath: Resource = .init() {
        didSet {
            if wadPath.fullPath == oldValue.fullPath {
                return
            }
            reload()
        }
    }

    var levelName: String = "" {
        didSet {
            if levelName == oldValue {
                return
            }
            reload()
        }
    }

    private var encoder: Sprite3DInput? {
        didSet {
            if let old = oldValue {
                removeRenderInputs(old)
            }
            if let new = encoder {
                addRenderInput(new)
            }
        }
    }

    private func reload() {
        guard !wadPath.path.isEmpty && !levelName.isEmpty && wadPath.path.lowercased().hasSuffix(".wad") else {
            return
        }
        let path = ResourcesPool.default.path(wadPath)
        let polygons = loadPolygonsFromWadFile(path, levelName)
        guard let polygons else {
            return
        }
        let baseIndexs = [2, 1, 0, 0, 3, 2]
        let baseIndexs2 = Array(baseIndexs.reversed())
        var vertexes: [VertexInput] = []
        var indexs: [UInt32] = []
        for i in 0..<polygons[0].count {
            let polygon = polygons[0].polygons[Int(i)];
            if polygon.right == 0 {
                for j in 0..<baseIndexs2.count {
                    let value = UInt32(baseIndexs2[j])
                    indexs = indexs + [UInt32(vertexes.count) + value]
                }
            } else {
                for j in 0..<baseIndexs2.count {
                    let value = UInt32(baseIndexs[j])
                    indexs = indexs + [UInt32(vertexes.count) + value]
                }
            }
            vertexes.append(
                .init(
                    position: .init(x: polygon.p1.x, y: polygon.p1.y, z: polygon.p1.z),
                    uv: .init(polygon.uv1.x, polygon.uv1.y),
                    atlas: polygon.atlas
                )
            )
            vertexes.append(
                .init(
                    position: .init(x: polygon.p2.x, y: polygon.p2.y, z: polygon.p2.z),
                    uv: .init(polygon.uv2.x, polygon.uv2.y),
                    atlas: polygon.atlas
                )
            )
            vertexes.append(
                .init(
                    position: .init(x: polygon.p3.x, y: polygon.p3.y, z: polygon.p3.z),
                    uv: .init(polygon.uv3.x, polygon.uv3.y),
                    atlas: polygon.atlas
                )
            )
            vertexes.append(
                .init(
                    position: .init(x: polygon.p4.x, y: polygon.p4.y, z: polygon.p4.z),
                    uv: .init(polygon.uv4.x, polygon.uv4.y),
                    atlas: polygon.atlas
                )
            )


        }
        print("[T]\(vertexes.count)")

        let size = (polygons[0].textureSize * polygons[0].textureSize * 4)
        let buffer = UnsafeBufferPointer(start: polygons[0].texture, count: Int(size))

        let texture = Texture(data: Array(buffer), width: Int(polygons[0].textureSize), height: Int(polygons[0].textureSize))
        let atlasInput = (0..<polygons[0].atlasSize).map { index in
            AtlasInput(
                uvPosition: .init(
                    x: polygons[0].atlas[Int(index)].position.x,
                    y: polygons[0].atlas[Int(index)].position.y
                ),
                uvSize: .init(
                    x: polygons[0].atlas[Int(index)].size.x,
                    y: polygons[0].atlas[Int(index)].size.y
                )
            )
        }

        deletePoligonInfo(polygons)
        let encoder = Sprite3DInput(
            texture: texture,
            vertexs: vertexes,
            atlas: atlasInput
        )
//        if vert != vertexes {
//            print("[T]error")
//            for i in 0..<vertexes.count { if (vertexes[i] != vert?[i]) { print("[T]\(i)") } }
//        }

        vert = vertexes
        encoder.vertexIndexs.values = indexs
        self.encoder = encoder
    }

    var vert: [VertexInput]?
}

@EditorModification<WADNode>
struct WADNodeModification: IEditorModification {
    @Editable var wadPath: Resource = .init("")
    @Editable var levelName: String = ""
}
