public func convert<T>(_ object: Any) throws -> T {
    guard let result = object as? T else {
        throw StorageError.baseError("'\(object)' is not '\(T.self)'")
    }
    return result
}

public func notNil<T>(_ object: T?, message: String = "object not load") throws -> T {
    guard let result = object else {
        throw StorageError.baseError(message)
    }
    return result
}
