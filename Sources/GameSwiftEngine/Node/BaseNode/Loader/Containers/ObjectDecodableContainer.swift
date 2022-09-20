import Foundation

struct ObjectDecodableContainer: Decodable {
    struct SinglContainer: Decodable {
        let container: SingleValueDecodingContainer

        init(from decoder: Decoder) throws {
            container = try decoder.singleValueContainer()
        }
    }

    let typeIdentifier: String
    let container: SingleValueDecodingContainer

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ObjectStorageContainerKey.self)
        self.typeIdentifier = try container.decode(String.self, forKey: .typeIdentifier)
        self.container = try container.decode(SinglContainer.self, forKey: .object).container
    }
}
