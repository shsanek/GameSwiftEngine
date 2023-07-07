public enum Object3DNodeGeometrySource: Codable {
    case empty
    case object(_ object: InterQuakeImporter.Object)

    var object: InterQuakeImporter.Object? {
        switch self {
        case .object(let object):
            return object
        case .empty:
            return nil
        }
    }
}
