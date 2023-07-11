#if canImport(SwiftUI)
import SwiftUI
#endif
import ObjectEditor
import simd

@EditorModification<Object3DNode>
struct Object3DNodeModification: IEditorModification {
    @Editable var textureResource: Resource = .init("")
    @Editable var objectResource: Resource = .init("")
}
