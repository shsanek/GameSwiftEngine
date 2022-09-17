import MetalKit

final class MetalRenderFunction{
    private let device: MTLDevice
    private let renderState: MTLRenderPipelineState

    init(
        device: MTLDevice,
        function: MetalRenderFunctionName,
        pixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    ) throws {
        self.device = device
        let library = try device.makeDefaultLibrary(bundle: .module)

        guard let vertexFunction = library.makeFunction(name: function.vertexFunction) else {
            throw RenderError.message("error load Vertex Function")
        }
        guard let fragmentFunction = library.makeFunction(name: function.fragmentFunction) else {
            throw RenderError.message("error load Fragment Function")
        }
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = function.name
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

        renderState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }

    func start(
        encoder: MTLRenderCommandEncoder
    ) throws {
        encoder.setRenderPipelineState(renderState)
    }
}


typealias RenderFunctionsCache = Сache<MetalRenderFunctionName, MetalRenderFunction>

extension Сache where Key == MetalRenderFunctionName, Element == MetalRenderFunction {
    func get(with name: MetalRenderFunctionName, device: MTLDevice) throws -> MetalRenderFunction {
        try self.get(with: name) {
            try MetalRenderFunction(device: device, function: name)
        }
    }
}
