public func convert<T>(_ object: Any) throws -> T {
    guard let result = object as? T else {
        throw StorageError.baseError("'\(object)' is not '\(T.self)'")
    }
    return result
}
