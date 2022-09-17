public struct RenderInfo {
    public var size: Size = .init(width: 512, height: 512)

    public struct DepthInfo {
        public var arrayIndex: Int = 0
        public var depth: ITexture? = TextureFactory.makeDepthTexture(size: .init(width: 512, height: 512))
    }

    public struct ColorInfo {
        public var arrayIndex: Int = 0
        public var color: ITexture? = TextureFactory.makeColorTexture(size: .init(width: 512, height: 512))
    }

    var colorInfo: ColorInfo = .init()
    var depthInfo: DepthInfo = .init()
}
