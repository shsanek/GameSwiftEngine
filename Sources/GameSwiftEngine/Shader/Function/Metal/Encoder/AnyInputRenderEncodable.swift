import MetalKit

public protocol AnyRenderHandler: AnyObject {
}

extension AnyRenderHandler {
    func run(
        input: MetalRenderInput
    ) throws {
        try (self as? MetalRenderHandler)?.run(
            input: input
        )
    }
}

extension MetalRenderHandler {
    func run(
        input: MetalRenderInput
    ) throws {
        if var change = self as? ScreenSizeChangable {
            change.renderSize = .init(UInt32(input.size.x), UInt32(input.size.y))
        }
        if var change = self as? ProjectionChangable {
            change.projectionMatrix = input.projectionMatrix
        }
        if var change = self as? PositionChangable {
            change.positionMatrix = input.currentPosition
        }
        if var change = self as? LightInfoChangable {
            change.lightInfo = input.lightInfo
        }
        if var change = self as? CameraPositionChangable {
            change.cameraPositionMatrix = input.cameraPosition
        }
        try self.renderEncode(
            input.encoder,
            device: input.device,
            attributes: input.attributes,
            functionsСache: input.functionCache
        )
    }
}
