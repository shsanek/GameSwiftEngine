public enum Object3DNodeGeometrySource: Codable {
    case empty
    case iqe(_ file: String)
    case object(_ object: InterQuakeImporter.Object)

    var object: InterQuakeImporter.Object? {
        switch self {
        case .iqe(let file):
            return InterQuakeImporter.loadFile(file)
        case .object(let object):
            return object
        case .empty:
            return nil
        }
    }
}
