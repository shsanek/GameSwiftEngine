public struct Size: Hashable, Codable {
    public let width: GEFloat
    public let height: GEFloat

    public init(width: GEFloat, height: GEFloat) {
        self.width = width
        self.height = height
    }
}

public struct Point: Hashable, Codable {
    public let x: GEFloat
    public let y: GEFloat

    public init(x: GEFloat, y: GEFloat) {
        self.x = x
        self.y = y
    }
}
