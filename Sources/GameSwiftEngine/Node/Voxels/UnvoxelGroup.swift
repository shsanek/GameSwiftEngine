public struct UnvoxelGroupIdentifer: Hashable, Codable {
    let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }
}
