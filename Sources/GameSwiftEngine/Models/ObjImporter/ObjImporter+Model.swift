import simd
import Foundation

extension ObjImporter {
    public final class Object {
        let items: [Item]

        public struct Item {
            public let position: vector_float3
            public let uv: vector_float2
            public let normal: vector_float3
        }

        convenience init?(name: String, bundle: Bundle) {
            guard let url = bundle.url(forResource: name, withExtension: "obj") else {
                return nil
            }
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            guard let content = String(data: data, encoding: .utf8) else {
                return nil
            }
            self.init(content: content)
        }

        init(content: String) {
            let raws = content.split(separator: "\n").map { $0.split(separator: " ") }
            let positions = raws
                .filter { $0.count > 3 && $0[0] == "v" }
                .map {
                    vector_float3(GEFloat($0[1]) ?? 0, GEFloat($0[2]) ?? 0, GEFloat($0[3]) ?? 0)
                }
            let uvs = raws
                .filter { $0.count == 3 && $0[0] == "vt" }
                .map {
                    vector_float2(GEFloat($0[1]) ?? 0, GEFloat($0[2]) ?? 0)
                }
            let normals = raws
                .filter { $0.count > 3 && $0[0] == "vn" }
                .map {
                    vector_float3(GEFloat($0[1]) ?? 0, GEFloat($0[2]) ?? 0, GEFloat($0[3]) ?? 0)
                }

            let points = raws
                .filter { $0[0] == "f" }
                .map { points in
                    Self.makeItem(
                        Array(points.map { "\($0)" }),
                        positions: positions,
                        normals: normals,
                        uvs: uvs
                    )
                }

            self.items = points.flatMap { Self.poligon($0) }
        }

        static func poligon(_ items: [Item]) -> [Item] {
            var result = [Item]()
            for i in 1..<items.count - 1 {
                result.append(items[0])
                result.append(items[i])
                result.append(items[i + 1])
            }
            return result
        }

        static func makeItem(
            _ points: [String],
            positions: [vector_float3],
            normals: [vector_float3],
            uvs: [vector_float2]
        ) -> [Item] {
            let items: [Item] = points.filter { $0 != "f" }.map {
                $0.split(separator: "/").map { Int("\($0)") }
            }.map { indexs -> Item in
                let position = indexs[0].flatMap { positions[$0 - 1] }
                let uv = indexs[1].flatMap { uvs[$0 - 1] }
                let normal = indexs[2].flatMap { normals[$0 - 1] }

                return Item(
                    position: position ?? .zero,
                    uv: uv ?? .zero,
                    normal: normal ?? .zero
                )
            }
            return items
        }
    }
}

