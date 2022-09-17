import Metal

public enum TextureFactory {
    public static func makeColorTexture(size: Size) -> ITexture {
        let texureDescriptor = MTLTextureDescriptor()
        texureDescriptor.textureType = .type2D
        texureDescriptor.width = Int(size.width);
        texureDescriptor.height = Int(size.height);
        texureDescriptor.pixelFormat = .bgra8Unorm_srgb
        texureDescriptor.usage = [.renderTarget, .shaderRead]

        return LazyTexure(descriptor: texureDescriptor, size: size)
    }

    public static func makeDepthTexture(size: Size) -> ITexture {
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite, .pixelFormatView]
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.resourceOptions = [.storageModePrivate]

        return LazyTexure(descriptor: depthTextureDescriptor, size: size)
    }

    public static func makeArrayDepthTexture(size: Size, count: Int) -> ITexture {
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite, .pixelFormatView]
        depthTextureDescriptor.textureType = .type2DArray
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.arrayLength = count
        depthTextureDescriptor.resourceOptions = [.storageModePrivate]

        return LazyTexure(descriptor: depthTextureDescriptor, size: size)
    }
}

