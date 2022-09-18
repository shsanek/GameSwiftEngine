import simd

// For import .obj file
public final class ObjImporter {
    public static func load(_ content: String) -> Object {
        Object(content: content)
    }

    public static func loadFile(_ name: String) -> Object? {
        Object(name: name)
    }
}
