import MetalKit

final class MetalRenderFunction<Input: MetalInputRenderEncodable> {
    private let device: MTLDevice
    private let renderState: MTLRenderPipelineState?

    init(
        device: MTLDevice,
        name: String = "\(Input.self)",
        inputType: Input.Type = Input.self,
        pixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    ) throws {
        self.device = device
        let library = try device.makeDefaultLibrary(bundle: .module)

        if let MetalRenderFunction = inputType.render {
            guard let vertexFunction = library.makeFunction(name: MetalRenderFunction.vertexFunction) else {
                throw RenderError.message("error load Vertex Function")
            }
            guard let fragmentFunction = library.makeFunction(name: MetalRenderFunction.fragmentFunction) else {
                throw RenderError.message("error load Fragment Function")
            }
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.label = name
            pipelineStateDescriptor.vertexFunction = vertexFunction
            pipelineStateDescriptor.fragmentFunction = fragmentFunction
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
            pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

            renderState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } else {
            renderState = nil
        }
    }

    func render(
        buffer: MTLCommandBuffer,
        input: Input,
        viewport: MTLViewport,
        encoder: @autoclosure () -> MTLRenderCommandEncoder?
    ) throws {
        if let state = renderState {
            guard let renderEncoder = encoder() else {
                throw RenderError.message("incorect renderEncoder")
            }
            renderEncoder.label = UUID().uuidString
            renderEncoder.setRenderPipelineState(state)
            renderEncoder.setViewport(viewport)
            try input.renderEncode(renderEncoder, device: device)
        }
    }

    func render(
        buffer: MTLCommandBuffer,
        input: Input,
        viewport: MTLViewport,
        outTexture: MTLTexture
    ) throws {
        let descr = MTLRenderPassDescriptor()
        descr.colorAttachments[0].texture = outTexture
        descr.colorAttachments[0].loadAction = .dontCare
        let encoder = buffer.makeRenderCommandEncoder(descriptor: descr)

        try render(buffer: buffer, input: input, viewport: viewport, encoder: encoder)
    }
}
