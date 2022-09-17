final class Сache<Key: Hashable, Element> {
    private var values = [Key: Element]()

    init() {
    }

    func get(with key: Key, maker: () throws -> Element) throws -> Element {
        if let element = values[key] {
            return element
        }
        let element = try maker()
        values[key] = element
        return element
    }
}
