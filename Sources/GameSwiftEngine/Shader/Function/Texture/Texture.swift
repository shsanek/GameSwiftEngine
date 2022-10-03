import Foundation
import MetalKit

public final class Texture: ITexture, IMetalTexture, ISourceTexture {
    let data: [UInt8]
    public let width: Int
    public let height: Int
    public let sourcePath: String?

    public init(data: [UInt8], width: Int, height: Int, sourcePath: String? = nil) {
        self.data = data
        self.width = width
        self.height = height
        self.sourcePath = sourcePath
    }

    /// METAL

    private var mlTexture = MLTextureCache()

    public func getMLTexture(
        device: MTLDevice
    ) -> MTLTexture? {
        mlTexture.getMLTexture(texture: self, device: device, pixelFormat: .bgra8Unorm_srgb)
    }

    func getMLTexture(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    ) -> MTLTexture? {
        mlTexture.getMLTexture(texture: self, device: device, pixelFormat: pixelFormat)
    }
}


final class MLTextureCache {
    private var device: MTLDevice?
    private var pixelFormat: MTLPixelFormat?

    private var texture: MTLTexture?

    func getMLTexture(
        texture: Texture,
        device: MTLDevice,
        pixelFormat: MTLPixelFormat
    ) -> MTLTexture? {
        if let texture = self.texture, device === self.device {
            if pixelFormat != self.pixelFormat {
                self.texture = texture.makeTextureView(pixelFormat: pixelFormat)
            }
            return self.texture
        }
        let description = MTLTextureDescriptor()
        description.pixelFormat = pixelFormat
        description.height = texture.height
        description.width = texture.width
        description.usage = .shaderRead
        let result = device.makeTexture(descriptor: description)
        var data = texture.data

        result?.replace(
            region: .init(
                origin: .init(x: 0, y: 0, z: 0),
                size: .init(width: texture.width, height: texture.height, depth: 1)
            ),
            mipmapLevel: 0,
            withBytes: &data,
            bytesPerRow: texture.width * 4
        )
        guard let texture = result else {
            return nil
        }
        self.device = device
        self.pixelFormat = pixelFormat
        self.texture = texture
        return texture
    }
}

extension Texture {
    static func load(with image: CGImage, sourcePath: String? = nil) -> Texture? {
        let height = image.height
        let widht = image.width

        let pixelCount = widht * height
        var data: [UInt8] = Array(repeating: 0x00, count: pixelCount * 4)
        let mutBufPtr = UnsafeMutableBufferPointer(start: &data, count: data.count)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmapInfo =
            CGBitmapInfo.byteOrder32Big.rawValue |
            CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue

        let context = CGContext(
            data: mutBufPtr.baseAddress,
            width: widht,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: widht * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )

        context?.draw(image, in: .init(x: 0, y: 0, width: widht, height: height))
        var result: [UInt8] = Array(repeating: 0x00, count: pixelCount * 4)
        for i in 0..<pixelCount {
            let j = i * 4
            let r = data[j + 0]
            let g = data[j + 1]
            let b = data[j + 2]
            let a = data[j + 3]
            result[pixelCount * 4 - 1 - (j + 0)] = a
            result[pixelCount * 4 - 1 - (j + 1)] = r
            result[pixelCount * 4 - 1 - (j + 2)] = g
            result[pixelCount * 4 - 1 - (j + 3)] = b
        }
        return Texture(data: result, width: widht, height: height, sourcePath: sourcePath)
    }
}

#if canImport(UIKit)
import UIKit

public extension Texture {
    static func load(in file: String?) -> Texture? {
        guard let file = file, let image = UIImage(named: file)?.cgImage else {
            return nil
        }
        return load(with: image, sourcePath: file)
    }
}

#endif

#if canImport(Cocoa)
import Cocoa

public extension Texture {
    static func load(in file: String?) -> Texture? {
        guard let file = file, let image = NSImage(named: file)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        return load(with: image, sourcePath: file)
    }
}

#endif
