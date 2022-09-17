import simd

public final class InterQuakeImporter {
    public static func load(_ content: String) -> Object {
        InterQuakeImporter(content: content).load()
    }

    private var rows: [[String]] = []

    private init(content: String) {
        rows = content
            .replacingOccurrences(of: "\t", with: "")
            .split(separator: "\n")
            .map { $0.split(separator: " ").map { String($0) } }
    }

    private func load() -> Object {
        var poligons: [Poligon?] = []
        var frame: [Frame?] = []
        var vertex: [Vertex?] = []
        var bone: [Bone?] = []
        while rows.count > 0 {
            switch headerParameter() {
            case "frame":
                frame.append(getFrame(bones: bone.compactMap { $0 }))
            case "fm":
                poligons.append(getPoligon())
            case "vp":
                vertex.append(getVertex())
            case "joint":
                bone.append(getBone())
            default:
                break
            }
            _ = nextRow()
        }
        return .init(
            poligons: poligons.compactMap { $0 },
            frame: frame.compactMap { $0 },
            vertex: vertex.compactMap { $0 },
            bone: bone.compactMap { $0 }
        )
    }

    private func getBone() -> Bone? {
        guard let name = nameParameter(),
              let index = intParameter(),
              let transform = getBoneTransform()
        else {
            return nil
        }
        return .init(transform: transform, parent: index, name: name)
    }

    private func getFrame(bones: [Bone]) -> Frame? {
        let transforms = array(getBoneTransform)
        guard transforms.count == bones.count else {
            return nil
        }
        return .init(
            bones: bones.enumerated().map {
                Bone(
                    transform: transforms[$0.offset],
                    parent: $0.element.parent,
                    name: $0.element.name
                )
            }
        )
    }

    private func getPoligon() -> Poligon? {
        guard let a = intParameter(), let b = intParameter(), let c = intParameter() else {
            return nil
        }
        return .init(a: a, b: b, c: c)
    }

    private func getVertex() -> Vertex? {
        guard let position = getVector3() else {
            return nil
        }
        let uv = getUV()
        let normal = getNormal()
        let vb = getBindings()

        return .init(position: position, uv: uv, normal: normal, binding: vb ?? [])
    }

    private func getBindings() -> [Vertex.Binding]? {
        guard nextHeaderCheck("vb") else {
            return nil
        }
        return array(getBinding)
    }

    private func getUV() -> vector_float2? {
        guard nextHeaderCheck("vt"), let value = getVector2() else {
            return nil
        }
        return value
    }

    private func getNormal() -> vector_float3? {
        guard nextHeaderCheck("vn"), let value = getVector3() else {
            return nil
        }
        return value
    }

    private func getBinding() -> Vertex.Binding? {
        guard let index = intParameter(), let width = floatParameter() else {
            return nil
        }
        return .init(index: index, power: width)
    }

    private func array<T>(_ get: () -> T?) -> [T] {
        var result = [T]()
        while let element = get() {
            result.append(element)
        }
        return result
    }

    private func getBoneTransform() -> BoneTransform? {
        guard nextHeaderCheck("pq"), let t = getVector3(), let q = getVector4() else {
            return nil
        }
        let s = getVector3() ?? .one
        return .init(translate: t, quaternion: q, scale: s)
    }

    private func getVector2() -> vector_float2?  {
        guard let x = floatParameter(), let y = floatParameter() else {
            return nil
        }
        return vector_float2(x, y)
    }

    private func getVector3() -> vector_float3? {
        guard let x = floatParameter(), let y = floatParameter(), let z = floatParameter() else {
            return nil
        }
        return vector_float3(x, y, z)
    }

    private func getVector4() -> vector_float4?  {
        guard let x = floatParameter(), let y = floatParameter(), let z = floatParameter(), let w = floatParameter() else {
            return nil
        }
        return vector_float4(x, y, z, w)
    }


    private func intParameter() -> Int? {
        guard let content = rows.first?.first, let result = Int(content) else {
            return nil
        }
        removeParameters()
        return result
    }

    private func floatParameter() -> Float? {
        guard let content = rows.first?.first, let result = Float(content) else {
            return nil
        }
        removeParameters()
        return result
    }

    private func headerParameter() -> String? {
        guard let result = rows.first?.first else {
            return nil
        }
        removeParameters()
        return result
    }

    private func nameParameter() -> String? {
        guard let result = rows.first?.first?.replacingOccurrences(of: "\"", with: "") else {
            return nil
        }
        removeParameters()
        return result
    }

    private func nextHeaderCheck(_ header: String) -> Bool {
        guard rows.count > 1, let result = rows[1].first, result == header else {
            return false
        }
        _ = nextRow()
        removeParameters()
        return true
    }

    private func removeParameters() {
        guard rows.count > 0 else {
            return
        }
        rows[0].removeFirst()
    }

    private func nextRow() -> Bool {
        guard rows.count > 0 else {
            return false
        }
        rows.removeFirst()
        return true
    }
}


import Foundation

extension InterQuakeImporter {
    public static func loadFile(_ name: String) -> Object? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "iqe") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        guard let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        return InterQuakeImporter(content: content).load()
    }
}
