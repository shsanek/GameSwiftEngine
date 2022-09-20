import Foundation

struct ObjectEncodableContainer: Encodable {
    struct SinglContainer: Encodable {
        let modalSaver: (Encoder) throws -> Void

        func encode(to encoder: Encoder) throws {
            try modalSaver(encoder)
        }
    }

    let typeIdentifier: String
    let container: SinglContainer

    init(typeIdentifier: String, _ modalSaver: @escaping (Encoder) throws -> Void) {
        self.typeIdentifier = typeIdentifier
        self.container = .init(modalSaver: modalSaver)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ObjectStorageContainerKey.self)
        try container.encode(typeIdentifier, forKey: .typeIdentifier)
        try container.encode(self.container, forKey: .object)
    }
}
