import MetalKit

public protocol AnyInputRenderEncodable: AnyObject {
}

extension AnyInputRenderEncodable {
    func run(with functions: inout [String: AnyObject], input: MetalRenderInput) throws {
        try (self as? MetalInputRenderEncodable)?.run(with: &functions, input: input)
    }
}

extension MetalInputRenderEncodable {
    func run(with functions: inout [String: AnyObject], input: MetalRenderInput) throws {
        let name = Self.name
        typealias Function = MetalRenderFunction<Self>
        let function: Function = try ((functions[name] as? Function) ?? (Function(device: input.device)))
        functions[name] = function
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
        let viewPort = MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(input.size.x),
            height: Double(input.size.y),
            znear: -1,
            zfar: 1
        )

        try function.render(
            buffer: input.buffer,
            input: self,
            viewport: viewPort,
            encoder: input.encoder
        )
    }
}
