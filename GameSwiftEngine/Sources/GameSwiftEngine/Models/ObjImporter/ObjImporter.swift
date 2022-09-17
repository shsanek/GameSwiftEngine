import simd

public final class ObjImporter {
    public static func load(_ content: String) -> Object {
        Object(content: content)
    }

    public static func loadFile(_ name: String) -> Object? {
        Object(name: name)
    }
}
