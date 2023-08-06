#if canImport(SwiftUI)
import SwiftUI
#endif
import ObjectEditor
import simd

@EditorModification<Object3DNode>
struct Object3DNodeModification: IEditorModification {
    @Editable var objectResource: Resource = .init("")
}

public protocol ITexturable: AnyObject {
    var texture: ITexture? { get set }
}

@EditorModification<ITexturable>
struct TextureModification: IEditorModification {
    @Editable(mapper: ResourceMapper<TextureLoader>.directOptional.self) var texture: Resource = .init("")
}

public struct ResourceMapper<Loader: IResourceLoader>: IEditorDirectMapper {
    public static func objectToModel(_ object: Loader.Res) -> Resource {
        .init()
    }

    public static func modelToObject(_ model: Resource) -> Loader.Res? {
        try? ResourceManager.default.load(Loader.self, resource: model)
    }
}

public protocol IResourceLoader {
    associatedtype Res

    static func load(from data: Data) throws -> Res
}

public final class ResourceManager {
    public let pool: ResourcesPool
    public static let `default` = ResourceManager()

    private var simpleCache = [String: Any]()

    public init(pool: ResourcesPool = .default) {
        self.pool = pool
    }

    public func load<Loader: IResourceLoader>(_ loader: Loader.Type, resource: Resource) throws -> Loader.Res {
        if let obj = simpleCache[resource.fullPath] as? Loader.Res {
            return obj
        }
        let data = try pool.getData(resource)
        let obj = try Loader.load(from: data)
        simpleCache[resource.fullPath] = obj
        return obj
    }
}

public class LazyInterQuakeImporterContainer {
    let object: InterQuakeImporter.Object
    var vertexs: BufferContainer<VertexInput> {
        if let vertex = storageVertexsContainer {
            return vertex
        }
        let vertex: BufferContainer<VertexInput> = .init()
        vertex.values = object.getVertexs()
        return vertex
    }

    private var storageVertexsContainer: BufferContainer<VertexInput>? = nil

    public init(_ object: InterQuakeImporter.Object) {
        self.object = object
    }
}

public class LazyObjectImporterContainer {
    public let object: ObjImporter.Object

    public var vertexs: BufferContainer<VertexInput> {
        if let vertex = storageVertexsContainer {
            return vertex
        }
        let vertex: BufferContainer<VertexInput> = .init()
        vertex.values = object.geometryForInput()
        return vertex
    }

    private var storageVertexsContainer: BufferContainer<VertexInput>? = nil

    public init(_ object: ObjImporter.Object) {
        self.object = object
    }
}

extension Object3DNode {
    var textureResource: Resource {
        get {
            .init("")
        }
        set {
            self.texture = try? ResourceManager.default.load(TextureLoader.self, resource: newValue)
        }
    }

    var objectResource: Resource {
        get {
            .init("")
        }
        set {
            self.reload(try? ResourceManager.default.load(InterQuakeImporterLoader.self, resource: newValue))
        }
    }
}

import Foundation

extension IResourceLoader {
    public static func load(_ res: Resource) throws -> Res {
        try ResourceManager.default.load(Self.self, resource: res)
    }
}

public struct TextureLoader: IResourceLoader {
    public static func load(from data: Data) throws -> ITexture {
        guard let texture = Texture.load(in: data) else {
            throw EditorError.message("not load object")
        }
        return texture
    }
}

public struct InterQuakeImporterLoader: IResourceLoader {
    public static func load(from data: Data) throws -> LazyInterQuakeImporterContainer {
        guard
            let content = String(data: data, encoding: .utf8)
        else {
            throw EditorError.message("not load object")
        }
        return .init(InterQuakeImporter.load(content))
    }
}


public struct ObjectImporterLoader: IResourceLoader {
    public static func load(from data: Data) throws -> LazyObjectImporterContainer {
        guard
            let content = String(data: data, encoding: .utf8)
        else {
            throw EditorError.message("not load object")
        }
        return .init(ObjImporter.load(content))
    }
}
