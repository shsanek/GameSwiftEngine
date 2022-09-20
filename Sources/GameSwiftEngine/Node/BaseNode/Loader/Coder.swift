import Foundation

public protocol IDecoder {
    func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T
}

public protocol IEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONDecoder: IDecoder { }
extension JSONEncoder: IEncoder { }
