#if canImport(SwiftUI)
import SwiftUI
#endif
import ObjectEditor
import simd

public struct RotateMap: IEditorDirectMapper {
    public static func modelToObject(_ model: vector_float3) -> vector_float3? {
        return model / 180 * GEFloat.pi
    }

    public static func fillObject(_ object: inout vector_float3, from model: vector_float3) {
        object = model / 180 * GEFloat.pi
    }

    public static func objectToModel(_ object: vector_float3) -> vector_float3 {
        object / GEFloat.pi * 180
    }
}

@EditorModification<Node>
public struct NodeBaseModification: IEditorModification {
    @Editable public var isHidden: Bool = false

    @Editable(name: "position") public var localPosition: vector_float3 = .init(x: 0, y: 0, z: 0)
    @Editable(mapper: RotateMap.self, name: "rotate") public var localRotate: vector_float3 = .init(x: 0, y: 0, z: 0)
    @Editable public var scale: vector_float3 = .init(x: 1, y: 1, z: 1)
}
