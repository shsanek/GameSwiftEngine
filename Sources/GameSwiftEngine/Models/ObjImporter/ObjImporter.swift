import simd
import Foundation

// For import .obj file
public final class ObjImporter {
    public static func load(_ content: String) -> Object {
        Object(content: content)
    }

    public static func loadFile(_ name: String, bundle: Bundle) -> Object? {
        Object(name: name, bundle: bundle)
    }
}
