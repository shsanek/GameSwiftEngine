import Foundation

public struct ObjectLink: Codable, Hashable {
    let link: String

    public init(_ object: AnyObject) {
        link = "\(ObjectIdentifier(object))"
    }
}

