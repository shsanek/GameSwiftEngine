import MetalKit

protocol RenderFunction {
    func start(encoder: MTLRenderCommandEncoder) throws
}

final class MetalRenderFunction: RenderFunction {
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

final class MetalMeshRenderFunction: RenderFunction {
    private let device: MTLDevice
    private let renderState: MTLRenderPipelineState

    init(
        device: MTLDevice,
        function: MetalMeshFunctionName,
        pixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    ) throws {
        self.device = device
        let library = try device.makeDefaultLibrary(bundle: .module)

        guard let meshFunction = library.makeFunction(name: function.meshFunction) else {
            throw RenderError.message("error load Mesh Function")
        }
        guard let objectFunction = library.makeFunction(name: function.objectFunction) else {
            throw RenderError.message("error load Object Function")
        }
        guard let fragmentFunction = library.makeFunction(name: function.fragmentFunction) else {
            throw RenderError.message("error load Fragment Function")
        }
        let pipelineStateDescriptor = MTLMeshRenderPipelineDescriptor()
        pipelineStateDescriptor.label = function.name

        pipelineStateDescriptor.objectFunction = objectFunction
        pipelineStateDescriptor.payloadMemoryLength = 16 * 1024
        pipelineStateDescriptor.maxTotalThreadsPerObjectThreadgroup = 16

        pipelineStateDescriptor.meshFunction = meshFunction
        pipelineStateDescriptor.maxTotalThreadsPerMeshThreadgroup = 96

        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

        renderState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor, options: .argumentInfo).0
    }

    func start(
        encoder: MTLRenderCommandEncoder
    ) throws {
        encoder.setRenderPipelineState(renderState)
    }
}


typealias RenderFunctionsCache = Сache<String, RenderFunction>

extension Сache where Key == String, Element == RenderFunction {
    func get(with name: MetalRenderFunctionName, device: MTLDevice) throws -> RenderFunction {
        try self.get(with: name.id) {
            try MetalRenderFunction(device: device, function: name)
        }
    }

    func get(with name: MetalMeshFunctionName, device: MTLDevice) throws -> RenderFunction {
        try self.get(with: name.id) {
            try MetalMeshRenderFunction(device: device, function: name)
        }
    }
}
