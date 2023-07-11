#if canImport(SwiftUI)
import SwiftUI
#endif
import ObjectEditor
import simd

@EditorModification<Node>
struct NodeBaseModification: IEditorModification {
    @Editable var isHidden: Bool = false

    @Editable(name: "position") var localPosition: vector_float3 = .init(x: 0, y: 0, z: 0)
    @Editable(name: "rotate") var localRotate: vector_float3 = .init(x: 0, y: 0, z: 0)
    @Editable var scale: vector_float3 = .init(x: 1, y: 1, z: 1)
}
